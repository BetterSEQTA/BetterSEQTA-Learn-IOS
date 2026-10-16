import Data
import Domain
import XCTest

final class SeqtaResponseParsersTests: XCTestCase {
    func testParseLoginProfileFromFixture() throws {
        let data = try loadFixture("login_response.json")
        let payload = try JSONObjectHelpers.seqtaPayload(from: data)
        let profile = SeqtaResponseParsers.parseLoginProfile(payload: payload)
        XCTAssertEqual(profile?.id, 1001)
        XCTAssertEqual(profile?.userName, "student.demo")
        XCTAssertEqual(profile?.displayName, "Demo Student")
    }

    func testParseSubjectListFromFixture() throws {
        let data = try loadFixture("subjects_response.json")
        let payload = try JSONObjectHelpers.seqtaPayload(from: data)
        let subjects = SeqtaResponseParsers.parseSubjectList(payload: payload)
        XCTAssertEqual(subjects.count, 2)
        XCTAssertEqual(subjects[0].code, "MATH")
        XCTAssertEqual(subjects[1].code, "ENG")
    }

    func testParseCourseListFromFixture() throws {
        let data = try loadFixture("courses_response.json")
        let payload = try JSONObjectHelpers.seqtaPayload(from: data)
        let courses = SeqtaResponseParsers.parseCourseList(payload: payload)
        XCTAssertEqual(courses.count, 1)
        XCTAssertEqual(courses[0].subjectCode, "MATH")
        XCTAssertEqual(courses[0].title, "Term 1 Overview")
    }

    func testParseMessageListFromFixture() throws {
        let data = try loadFixture("messages_response.json")
        let payload = try JSONObjectHelpers.seqtaPayload(from: data)
        let messages = SeqtaResponseParsers.parseMessageList(payload: payload)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].id, 42)
        XCTAssertTrue(messages[0].unread)
    }

    func testParseMessageListReadsSeqtaMessagesArray() throws {
        let payload: [String: Any] = [
            "messages": [
                [
                    "id": 7,
                    "subject": "Assembly reminder",
                    "sender": "Ms Example",
                    "preview": "Please arrive by 8:45",
                    "date": "2026-09-02T08:00:00",
                    "read": false,
                    "starred": true,
                ],
            ],
        ]
        let messages = SeqtaResponseParsers.parseMessageList(payload: payload)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].title, "Assembly reminder")
        XCTAssertEqual(messages[0].subtitle, "Please arrive by 8:45")
        XCTAssertTrue(messages[0].unread)
        XCTAssertTrue(messages[0].starred)
    }

    func testParseMessageListFromActionListFixture() throws {
        let data = try loadFixture("messages_list_action.json")
        let payload = try JSONObjectHelpers.seqtaPayload(from: data)
        let messages = SeqtaResponseParsers.parseMessageList(payload: payload)
        XCTAssertEqual(messages.count, 1)
        XCTAssertEqual(messages[0].id, 42)
        XCTAssertEqual(messages[0].title, "Camp permission slip")
    }

    func testParseMessageDetailReadsContentsField() throws {
        let payload: [String: Any] = [
            "contents": "<p>Hello <strong>student</strong></p>",
        ]
        let detail = SeqtaResponseParsers.parseMessageDetail(payload: payload, messageId: 9)
        XCTAssertEqual(detail?.id, 9)
        XCTAssertTrue(detail?.htmlBody.contains("Hello") ?? false)
    }

    func testParseMessageDetailReadsAttachmentsAndReadState() throws {
        let payload: [String: Any] = [
            "contents": "<p>See attached</p>",
            "read": false,
            "starred": true,
            "files": [
                [
                    "id": 3,
                    "filename": "notes.pdf",
                    "mimetype": "application/pdf",
                    "size": "2048",
                    "uuid": "abc-123",
                ],
            ],
        ]
        let detail = SeqtaResponseParsers.parseMessageDetail(payload: payload, messageId: 11)
        XCTAssertEqual(detail?.attachments.count, 1)
        XCTAssertEqual(detail?.attachments[0].filename, "notes.pdf")
        XCTAssertEqual(detail?.attachments[0].uuid, "abc-123")
        XCTAssertFalse(detail?.read ?? true)
        XCTAssertTrue(detail?.starred ?? false)
    }

    func testParseUploadedMessageFileReadsPayloadId() throws {
        let json = """
        {"status":"200","payload":{"id":42,"filename":"report.pdf","size":1024}}
        """
        let data = Data(json.utf8)
        let file = SeqtaResponseParsers.parseUploadedMessageFile(data: data)
        XCTAssertEqual(file?.id, 42)
        XCTAssertEqual(file?.filename, "report.pdf")
        XCTAssertEqual(file?.byteCount, 1024)
    }

    func testParseUploadedMessageFileFromFixture() throws {
        let data = try loadFixture("message_upload_response.json")
        let file = SeqtaResponseParsers.parseUploadedMessageFile(data: data)
        XCTAssertEqual(file?.id, 99)
        XCTAssertEqual(file?.filename, "homework.pdf")
        XCTAssertEqual(file?.byteCount, 2048)
    }

    func testParseMessageListSetsHasAttachmentsFromFilesArray() throws {
        let payload: [String: Any] = [
            "messages": [
                [
                    "id": 5,
                    "subject": "Files",
                    "read": true,
                    "files": [["id": 1, "uuid": "u1", "filename": "a.png"]],
                ],
            ],
        ]
        let messages = SeqtaResponseParsers.parseMessageList(payload: payload)
        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages[0].hasAttachments)
    }

    func testParseAssessmentListReadsArrayPayload() throws {
        let json = """
        [
          {
            "id": 57612,
            "code": "ENG",
            "title": "Essay Draft",
            "due": "2026-09-10T15:00:00",
            "status": "UPCOMING"
          }
        ]
        """
        let payload = try JSONSerialization.jsonObject(with: Data(json.utf8))
        let assessments = SeqtaResponseParsers.parseAssessmentList(payload: payload)
        XCTAssertEqual(assessments.count, 1)
        XCTAssertEqual(assessments[0].id, 57612)
        XCTAssertEqual(assessments[0].subjectCode, "ENG")
        XCTAssertEqual(assessments[0].status, "UPCOMING")
    }

    func testParseAssessmentListReadsTasksObjectPayload() throws {
        let payload: [String: Any] = [
            "tasks": [
                ["id": 1, "code": "MATH", "name": "Test", "dueDate": "2026-09-03"],
            ],
        ]
        let assessments = SeqtaResponseParsers.parseAssessmentList(payload: payload)
        XCTAssertEqual(assessments.count, 1)
        XCTAssertEqual(assessments[0].subjectCode, "MATH")
    }

    func testParseAssessmentListReadsTasksWithResultsObject() throws {
        let payload: [String: Any] = [
            "tasks": [
                [
                    "id": 17764,
                    "code": "11MAM",
                    "title": "SAT 1 - Functions and Graphs",
                    "due": "2025-03-11",
                    "graded": true,
                    "status": "MARKS_RELEASED",
                    "results": ["grade": "A", "percentage": 100],
                ],
            ],
        ]
        let assessments = SeqtaResponseParsers.parseAssessmentList(payload: payload)
        XCTAssertEqual(assessments.count, 1)
        XCTAssertEqual(assessments[0].grade, "A")
        XCTAssertEqual(assessments[0].percentage, 100)
        XCTAssertTrue(assessments[0].marked)
        XCTAssertEqual(assessments[0].status, "MARKS_RELEASED")
    }

    func testParseAssessmentListReadsSyllabusCriteriaGrades() throws {
        let payload: [String: Any] = [
            "syllabus": [
                [
                    "id": 1,
                    "assessments": [
                        [
                            "id": 16630,
                            "code": "11ESH",
                            "title": "Poetry Comparison",
                            "due": "2025-03-19",
                            "graded": true,
                            "status": "MARKS_RELEASED",
                            "criteria": [
                                ["id": 18084, "label": "Achievement", "grade": "B", "percentage": 85],
                            ],
                        ],
                    ],
                ],
            ],
        ]
        let assessments = SeqtaResponseParsers.parseAssessmentList(payload: payload)
        XCTAssertEqual(assessments.count, 1)
        XCTAssertEqual(assessments[0].grade, "B")
        XCTAssertEqual(assessments[0].percentage, 85)
        XCTAssertTrue(assessments[0].marked)
    }

    func testParseAssessmentDetailReadsCriteriaAndEngagement() throws {
        let payload: [String: Any] = [
            "title": "Poetry Comparison",
            "code": "11ESH",
            "due": "2025-03-19",
            "graded": true,
            "criteria": [
                [
                    "name": "Achievement",
                    "grade": "B",
                    "percentage": 85,
                ],
            ],
            "engagement": ["feedbackComment": "Strong analysis"],
            "expectations": [["name": "Use textual evidence"]],
        ]
        let fallback = Assessment(
            id: 16630,
            title: "Fallback",
            subjectCode: "ENG",
            dueDate: nil,
            status: nil
        )
        let detail = SeqtaResponseParsers.parseAssessmentDetail(payload: payload, fallback: fallback)
        XCTAssertEqual(detail.title, "Poetry Comparison")
        XCTAssertEqual(detail.grade, "B")
        XCTAssertEqual(detail.percentage, 85)
        XCTAssertEqual(detail.feedbackComment, "Strong analysis")
        XCTAssertEqual(detail.expectations, ["Use textual evidence"])
        XCTAssertEqual(detail.criteria.count, 1)
    }

    func testParseMessageRecipientsFromItemsObject() throws {
        let payload: [String: Any] = [
            "items": [
                [
                    "id": 12,
                    "xx_display": "Ms Example",
                    "year": "12",
                ],
            ],
        ]
        let recipients = SeqtaResponseParsers.parseMessageRecipients(payload: payload, isStaff: true)
        XCTAssertEqual(recipients.count, 1)
        XCTAssertEqual(recipients[0].displayName, "Ms Example")
        XCTAssertTrue(recipients[0].isStaff)
    }

    func testHasSubmissionEntriesDetectsNonEmptyPayload() {
        XCTAssertTrue(SeqtaResponseParsers.hasSubmissionEntries(payload: ["id": 1]))
        XCTAssertFalse(SeqtaResponseParsers.hasSubmissionEntries(payload: [:]))
    }

    func testParseAssessmentSubmissionsReadsStudentFiles() throws {
        let payload: [[String: Any]] = [
            [
                "id": 42,
                "filename": "essay.pdf",
                "mimetype": "application/pdf",
                "size": "2048",
                "uuid": "abc-uuid",
                "staff": false,
            ],
            [
                "id": 43,
                "filename": "feedback.pdf",
                "mimetype": "application/pdf",
                "size": 1024,
                "staff": true,
            ],
        ]
        let files = SeqtaResponseParsers.parseAssessmentSubmissions(payload: payload)
        XCTAssertEqual(files.count, 2)
        XCTAssertEqual(files[0].filename, "essay.pdf")
        XCTAssertFalse(files[0].isStaff)
        XCTAssertTrue(files[1].isStaff)
    }

    func testParseAssessmentDetailReadsRubricAndSubmissionSettings() throws {
        let payload: [String: Any] = [
            "title": "Rubric task",
            "code": "ENG",
            "submissionSettings": ["fileSubmissionEnabled": true],
            "availableGrades": ["A", "B", "C"],
            "criteria": [
                [
                    "label": "Analysis",
                    "rubric": [
                        "lines": [
                            [
                                "id": 1,
                                "title": "Evidence",
                                "descriptors": [
                                    ["id": 10, "grade": "A", "content": "Excellent"],
                                    ["id": 11, "grade": "B", "content": "Good"],
                                ],
                            ],
                        ],
                    ],
                    "rubricScore": [
                        "1": ["id": 10, "grade": "A"],
                    ],
                ],
            ],
        ]
        let fallback = Assessment(id: 1, title: "x", subjectCode: "ENG", dueDate: nil, status: nil)
        let detail = SeqtaResponseParsers.parseAssessmentDetail(payload: payload, fallback: fallback)
        XCTAssertTrue(detail.fileSubmissionEnabled)
        XCTAssertEqual(detail.availableGrades, ["A", "B", "C"])
        XCTAssertEqual(detail.criteria.count, 1)
        XCTAssertTrue(detail.criteria[0].hasRubricTable)
        XCTAssertEqual(detail.criteria[0].rubricScores["1"]?.descriptorId, 10)
    }

    func testParseAssessmentListReadsCriteriaResultsPercentage() throws {
        let payload: [String: Any] = [
            "tasks": [
                [
                    "id": 57163,
                    "code": "ENG",
                    "title": "Interpretive Task",
                    "due": "2023-11-01",
                    "marked": true,
                    "status": "OVERDUE",
                    "criteria": [
                        [
                            "label": "Interpretive",
                            "results": ["percentage": 65, "score": 13],
                        ],
                    ],
                ],
            ],
        ]
        let assessments = SeqtaResponseParsers.parseAssessmentList(payload: payload)
        XCTAssertEqual(assessments.count, 1)
        XCTAssertEqual(assessments[0].percentage, 65)
        XCTAssertTrue(assessments[0].marked)
        XCTAssertEqual(assessments[0].status, "MARKS_RELEASED")
    }

    func testParseTimetableLessonsReadsSeqtaRows() throws {
        let payload: [String: Any] = [
            "items": [
                [
                    "date": "2026-09-02",
                    "from": "09:00:00",
                    "until": "09:50:00",
                    "code": "ENG",
                    "description": "English",
                    "room": "B12",
                ],
            ],
        ]
        let lessons = SeqtaResponseParsers.parseTimetableLessons(payload: payload)
        XCTAssertEqual(lessons.count, 1)
        XCTAssertEqual(lessons[0].subjectCode, "ENG")
        XCTAssertEqual(lessons[0].title, "English")
        XCTAssertEqual(lessons[0].room, "B12")
        XCTAssertEqual(lessons[0].fromTime, "09:00:00")
        XCTAssertEqual(lessons[0].untilTime, "09:50:00")
        XCTAssertNil(lessons[0].teacherName)
    }

    func testParseTimetableLessonsReadsStaffField() throws {
        let payload: [String: Any] = [
            "items": [
                [
                    "date": "2026-09-02",
                    "from": "09:00:00",
                    "until": "09:50:00",
                    "code": "ENG",
                    "description": "English",
                    "room": "B12",
                    "staff": "Ms Example",
                ],
            ],
        ]
        let lessons = SeqtaResponseParsers.parseTimetableLessons(payload: payload)
        XCTAssertEqual(lessons[0].teacherName, "Ms Example")
    }

    func testParseCourseContentReadsModuleDocument() throws {
        let document = """
        {"document":{"modules":[{"uuid":"a","type":"title","content":{"value":"Welcome"},"prevModule":null,"nextModule":null},{"uuid":"b","type":"text","content":{"content":{"blocks":[{"text":"Course intro paragraph.","type":"unstyled"}],"entityMap":{}}},"prevModule":"a","nextModule":null}]}}
        """
        let payload: [String: Any] = [
            "c": "AEENG1",
            "t": "11 ATAR English",
            "document": document,
            "w": [[["t": "Week 1 intro", "h": "Read chapter 1"]]],
            "cf": [
                [
                    "id": 1,
                    "filename": "Syllabus.pdf",
                    "size": "1024",
                    "uuid": "file-uuid",
                    "mimetype": "application/pdf",
                ],
            ],
        ]
        let content = SeqtaResponseParsers.parseCourseContent(payload: payload)
        XCTAssertEqual(content?.code, "AEENG1")
        XCTAssertEqual(content?.title, "11 ATAR English")
        XCTAssertEqual(content?.overviewBlocks.count, 2)
        XCTAssertEqual(content?.lessons.count, 1)
        XCTAssertEqual(content?.lessons[0].weekIndex, 0)
        XCTAssertEqual(content?.lessons[0].title, "Week 1 intro")
        XCTAssertEqual(content?.lessons[0].homework, "Read chapter 1")
        XCTAssertEqual(content?.courseFiles.count, 1)
        XCTAssertEqual(content?.courseFiles[0].filename, "Syllabus.pdf")
        XCTAssertFalse(content?.documentParseError ?? true)
    }

    func testParseCourseContentReadsOverviewHTMLField() throws {
        let payload: [String: Any] = [
            "c": "ENG",
            "t": "English",
            "o": "<p><strong>Unit overview</strong></p>",
            "document": "{\"document\":{\"modules\":[{\"uuid\":\"a\",\"type\":\"title\",\"content\":{\"value\":\"Welcome\"},\"prevModule\":null,\"nextModule\":null}]}}",
        ]
        let content = SeqtaResponseParsers.parseCourseContent(payload: payload)
        XCTAssertEqual(content?.overviewBlocks.count, 2)
        XCTAssertEqual(content?.overviewBlocks.first, .html("<p><strong>Unit overview</strong></p>"))
    }

    func testParseCourseContentReadsLegacyEditorModuleDocument() throws {
        let document = """
        {"document":{"theme":"theme-uuid","modules":[{"uuid":"cover","type":"be8a6c4b-25b7-4129-bfcc-040ce937fab3","content":null},{"uuid":"body","type":"0d49d130-c197-421d-a56a-d1ba0a67cfc0","content":{"content":"<p><strong>Unit 1 overview body</strong></p>"}}]}}
        """
        let payload: [String: Any] = [
            "c": "AEENG1",
            "t": "11 ATAR English",
            "document": document,
        ]
        let content = SeqtaResponseParsers.parseCourseContent(payload: payload)
        XCTAssertEqual(content?.overviewBlocks.count, 1)
        if case .html(let html) = content?.overviewBlocks.first {
            XCTAssertTrue(html.contains("Unit 1 overview body"))
        } else {
            XCTFail("Expected legacy editor HTML block")
        }
        XCTAssertEqual(content?.themeReference, "theme-uuid")
    }

    func testParseCourseContentReadsInlineLessonHTMLAndResources() throws {
        let payload: [String: Any] = [
            "c": "SCI",
            "t": "Science",
            "w": [[
                [
                    "t": "Lab safety",
                    "l": "<p>Wear goggles in the lab.</p>",
                    "r": [
                        [
                            "uuid": "res-uuid",
                            "t": "Safety sheet",
                            "filename": "safety.pdf",
                            "size": "2048",
                            "mimetype": "application/pdf",
                        ],
                    ],
                ],
            ]],
        ]
        let content = SeqtaResponseParsers.parseCourseContent(payload: payload)
        XCTAssertEqual(content?.lessons.count, 1)
        XCTAssertEqual(content?.lessons[0].title, "Lab safety")
        XCTAssertEqual(content?.lessons[0].blocks.count, 1)
        XCTAssertEqual(content?.lessons[0].resources.count, 1)
        XCTAssertEqual(content?.lessons[0].resources[0].filename, "Safety sheet")
    }

    func testParseCourseDocumentThemesReadsCatalogPayload() throws {
        let payload: [[String: Any]] = [
            [
                "uuid": "theme-1",
                "name": "Biology",
                "accentColour": "#4e9a06",
                "accentContrastColour": "#fff",
                "textColour": "#061463",
                "documentBackground": "#51970d",
                "cardBackground": "#f8f8f8",
                "moduleBackground": "rgba(255, 255, 255, 0.8)",
                "cardBorderColour": "#eee",
                "fontFamily": "Montserrat",
                "fontSize": "14pt",
                "applyImage": true,
                "userfile": ["name": "th.jpg", "id": 86821, "uuid": "744b4bc9-ce16-42f3-9e0f-03d6f03c6b8d"],
            ],
        ]
        let themes = SeqtaResponseParsers.parseCourseDocumentThemes(payload: payload)
        XCTAssertEqual(themes.count, 1)
        XCTAssertEqual(themes[0].name, "Biology")
        XCTAssertEqual(themes[0].headerImageUUID, "744b4bc9-ce16-42f3-9e0f-03d6f03c6b8d")
    }

    func testParseTimetableLessonsSkipsRowsMissingRequiredFields() throws {
        let payload: [String: Any] = [
            "items": [
                ["date": "2026-09-02", "code": "ENG"],
            ],
        ]
        XCTAssertTrue(SeqtaResponseParsers.parseTimetableLessons(payload: payload).isEmpty)
    }

    func testParseSubjectListReadsFolderArrayPayload() throws {
        let json = """
        [
          {
            "code": "2026S",
            "active": 1,
            "id": 33,
            "subjects": [
              {
                "code": "AEENG1",
                "title": "11 ATAR English 2026",
                "metaclass": 14890,
                "programme": 6646
              }
            ]
          },
          {
            "code": "2025S",
            "id": 31,
            "subjects": [
              {
                "code": "10MAT2",
                "title": "10.2 Mathematics",
                "metaclass": 13776
              }
            ]
          }
        ]
        """
        let payload = try JSONSerialization.jsonObject(with: Data(json.utf8))
        let subjects = SeqtaResponseParsers.parseSubjectList(payload: payload)
        XCTAssertEqual(subjects.count, 1)
        XCTAssertEqual(subjects[0].code, "AEENG1")
    }

    func testParsePortalListReadsArrayPayload() throws {
        let json = """
        [
          {
            "id": 47,
            "label": "STUDENT HANDBOOK",
            "priority": 10,
            "uuid": "c6f3763a-ecf0-4dc0-9ec4-868a4ac658d1",
            "url": ""
          },
          {
            "id": 3,
            "label": "Study Resources",
            "priority": 20,
            "uuid": "cfe3a568-8a52-4fb1-bfa9-544688bb20ab",
            "url": "https://example.com"
          }
        ]
        """
        let payload = try JSONSerialization.jsonObject(with: Data(json.utf8))
        let portals = SeqtaResponseParsers.parsePortalList(payload: payload)
        XCTAssertEqual(portals.count, 2)
        XCTAssertEqual(portals[0].title, "STUDENT HANDBOOK")
        XCTAssertEqual(portals.last?.url, "https://example.com")
    }

    func testParseNoticeListReadsDatePayload() throws {
        let json = """
        [
          {
            "colour": "#ff5d5d",
            "label_title": "Student Office Helper",
            "contents": "<p>Office Helper roster</p>",
            "staff": "Miss Sarah Wyeth",
            "label": 76,
            "title": "Office Helper"
          }
        ]
        """
        let payload = try JSONSerialization.jsonObject(with: Data(json.utf8))
        let notices = SeqtaResponseParsers.parseNoticeList(payload: payload)
        XCTAssertEqual(notices.count, 1)
        XCTAssertEqual(notices[0].title, "Office Helper")
        XCTAssertEqual(notices[0].labelId, 76)
        XCTAssertEqual(notices[0].contents, "<p>Office Helper roster</p>")
    }

    func testNoticePlainTextStripsHTML() {
        let notice = Notice(
            title: "Test",
            labelTitle: nil,
            labelId: nil,
            colour: nil,
            staff: nil,
            contents: "<p>Hello <strong>world</strong></p>"
        )
        XCTAssertEqual(notice.plainTextContents, "Hello world")
        XCTAssertEqual(notice.contentPreview(maxLength: 50), "Hello world")
    }

    func testParseLoginProfileReadsNestedPayloadAndFieldAliases() throws {
        let payload: [String: Any] = [
            "user": [
                "userId": 2550,
                "username": "student2025",
                "name": "Student Name",
            ],
        ]
        let profile = SeqtaResponseParsers.parseLoginProfile(payload: payload)
        XCTAssertEqual(profile?.id, 2550)
        XCTAssertEqual(profile?.userName, "student2025")
        XCTAssertEqual(profile?.displayName, "Student Name")
    }

    func testParseLoginProfileReturnsNullWhenRequiredFieldsMissing() {
        let payload: [String: Any] = ["status": "active", "type": "student"]
        XCTAssertNil(SeqtaResponseParsers.parseLoginProfile(payload: payload))
    }

    private func loadFixture(_ name: String) throws -> Data {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name.replacingOccurrences(of: ".json", with: ""), withExtension: "json") else {
            XCTFail("Missing fixture \(name)")
            throw NSError(domain: "tests", code: 1)
        }
        return try Data(contentsOf: url)
    }
}

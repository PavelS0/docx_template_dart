## 0.1.0
- Initial version

## 0.1.1
- Fiexed warnings, code formatting, parameterized open/save methods

## 0.2.0
- Сhanged the load/save interface to support Flutter
- Various bug fixes and improvements

## 0.2.1
- Removed unused import of dart:io, fixed support dart:js
- Updated package:xml to newer 4.* version

## 0.2.2
- TextContent now accept text of dynamic type
- Disable pretty output

## 0.2.3
- Fixed StateError (Bad state: No element) in _findFirstChild

## 0.2.4
- Added support for multiline strings

## 0.2.5
- Added partial support for inserting images (NOTE: Only in NON repeated fields, not work in tables, lists)
- Refactoring DocxEntry classes

## 0.2.6
- Fixed The getter 'rootElement' was called on null 

## 0.2.7
- Added support for getiing image from relationship file by id

## 0.2.8
- Added support for displaying images in a table

## 0.2.9
- Original Content in the text tag now is not deleted if Content or Content.text is null

## 0.2.10
- Added options in DocxTemplate.generate, allowing save sdt tags
- XML copy optimizations 

## 0.3.0-nullsafety
- Pre-release of nullsafity version

## 0.3.0
- Attempt to fix concurrent modification

## 0.3.1
- Fixed broken TagPolicy export
- Unrecognized tags are no longer deleted

## 0.3.3
- Add test
- Fixed null safety for xml package
- Added function dor get all tags

## 0.3.4
- Attempt to fix archive saving
- Added new ImagePolicy parameter to DocxTemplate.generate

## 0.3.5
- Fix file currupting when image removed from document

## 0.3.6
- updated sdk version

## 0.4.0
- updated to dart ^3.0.0
- merged PR #48
 -  header and footer modification
 -   fix lose reference after callings getTags
 -   xml update
 -   add hyperlink (use link tag and use HyperlinkContent(
            key: "link",
            text: "My new link",
            url: "https://www.youtube.com/",
        ))
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pluto_grid/pluto_grid.dart';

import '../helper/column_helper.dart';
import '../helper/row_helper.dart';
import '../helper/test_helper_util.dart';

void main() {
  const columnWidth = PlutoGridSettings.columnWidth;

  testWidgets(
    'Directionality 가 rtl 인 경우 rtl 상태가 적용 되어야 한다.',
    (WidgetTester tester) async {
      // given
      late final PlutoGridStateManager stateManager;
      final columns = ColumnHelper.textColumn('header');
      final rows = RowHelper.count(3, columns);

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PlutoGrid(
                columns: columns,
                rows: rows,
                onLoaded: (e) => stateManager = e.stateManager,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(stateManager.isLTR, false);
      expect(stateManager.isRTL, true);
    },
  );

  testWidgets(
    'Directionality 가 rtl 인 경우 컬럼의 frozen 에 따라 방향에 맞게 위치해야 한다.',
    (WidgetTester tester) async {
      // given
      await TestHelperUtil.changeWidth(
        tester: tester,
        width: 1400,
        height: 600,
      );
      final columns = ColumnHelper.textColumn('header', count: 6);
      final rows = RowHelper.count(3, columns);

      columns[0].frozen = PlutoColumnFrozen.start;
      columns[1].frozen = PlutoColumnFrozen.end;
      columns[2].frozen = PlutoColumnFrozen.start;
      columns[3].frozen = PlutoColumnFrozen.end;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: PlutoGrid(
                columns: columns,
                rows: rows,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final firstStartColumn = find.text('header0');
      final secondStartColumn = find.text('header2');
      final firstBodyColumn = find.text('header4');
      final secondBodyColumn = find.text('header5');
      final firstEndColumn = find.text('header1');
      final secondEndColumn = find.text('header3');

      final firstStartColumnDx = tester.getTopRight(firstStartColumn).dx;
      final secondStartColumnDx = tester.getTopRight(secondStartColumn).dx;
      final firstBodyColumnDx = tester.getTopRight(firstBodyColumn).dx;
      final secondBodyColumnDx = tester.getTopRight(secondBodyColumn).dx;
      // frozen.end 컬럼은 전체 넓이로 인해 중앙 빈공간이 있어 좌측에서 위치 확인
      final firstEndColumnDx = tester.getTopLeft(firstEndColumn).dx;
      final secondEndColumnDx = tester.getTopLeft(secondEndColumn).dx;

      double expectOffset = columnWidth;
      expect(firstStartColumnDx - secondStartColumnDx, expectOffset);

      expectOffset = columnWidth + PlutoGridSettings.gridBorderWidth;
      expect(secondStartColumnDx - firstBodyColumnDx, expectOffset);

      expectOffset = columnWidth;
      expect(firstBodyColumnDx - secondBodyColumnDx, expectOffset);

      // end 컬럼은 중앙 컬럼보다 좌측에 위치해야 한다.
      expect(firstEndColumnDx, lessThan(secondBodyColumnDx - columnWidth));

      expectOffset = columnWidth;
      expect(firstEndColumnDx - secondEndColumnDx, expectOffset);
    },
  );

  testWidgets('createFooter 를 설정 한 경우 footer 가 출력 되어야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = ColumnHelper.textColumn('header');
    final rows = RowHelper.count(3, columns);

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            createFooter: (stateManager) {
              return const Text('Footer widget.');
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // then
    final footer = find.text('Footer widget.');
    expect(footer, findsOneWidget);
  });

  testWidgets(
      'header 에 PlutoPagination 을 설정 한 경우 PlutoPagination 가 렌더링 되어야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = ColumnHelper.textColumn('header');
    final rows = RowHelper.count(3, columns);

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            createHeader: (stateManager) {
              return PlutoPagination(stateManager);
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // then
    final found = find.byType(PlutoPagination);
    expect(found, findsOneWidget);
  });

  testWidgets(
      'footer 에 PlutoPagination 을 설정 한 경우 PlutoPagination 가 렌더링 되어야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = ColumnHelper.textColumn('header');
    final rows = RowHelper.count(3, columns);

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            createFooter: (stateManager) {
              return PlutoPagination(stateManager);
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // then
    final found = find.byType(PlutoPagination);
    expect(found, findsOneWidget);
  });

  testWidgets('cell 값이 출력 되어야 한다.', (WidgetTester tester) async {
    // given
    final columns = ColumnHelper.textColumn('header');
    final rows = RowHelper.count(3, columns);

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // then
    final cell1 = find.text('header0 value 0');
    expect(cell1, findsOneWidget);

    final cell2 = find.text('header0 value 1');
    expect(cell2, findsOneWidget);

    final cell3 = find.text('header0 value 2');
    expect(cell3, findsOneWidget);
  });

  testWidgets('header 탭 후 정렬 되어야 한다.', (WidgetTester tester) async {
    // given
    final columns = ColumnHelper.textColumn('header');
    final rows = RowHelper.count(3, columns);

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    Finder headerInkWell = find.descendant(
        of: find.byKey(columns.first.key), matching: find.byType(InkWell));

    // then
    await tester.tap(headerInkWell);
    // Ascending
    expect(rows[0].cells['header0']!.value, 'header0 value 0');
    expect(rows[1].cells['header0']!.value, 'header0 value 1');
    expect(rows[2].cells['header0']!.value, 'header0 value 2');

    await tester.tap(headerInkWell);
    // Descending
    expect(rows[0].cells['header0']!.value, 'header0 value 2');
    expect(rows[1].cells['header0']!.value, 'header0 value 1');
    expect(rows[2].cells['header0']!.value, 'header0 value 0');

    await tester.tap(headerInkWell);
    // Original
    expect(rows[0].cells['header0']!.value, 'header0 value 0');
    expect(rows[1].cells['header0']!.value, 'header0 value 1');
    expect(rows[2].cells['header0']!.value, 'header0 value 2');
  });

  testWidgets('셀 값 변경 후 헤더를 탭하면 변경 된 값에 맞게 정렬 되어야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = ColumnHelper.textColumn('header');
    final rows = RowHelper.count(3, columns);

    PlutoGridStateManager? stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    Finder firstCell = find.byKey(rows.first.cells['header0']!.key);

    // 셀 선택
    await tester.tap(
        find.descendant(of: firstCell, matching: find.byType(GestureDetector)));

    expect(stateManager!.isEditing, false);

    // 수정 상태로 변경
    await tester.tap(
        find.descendant(of: firstCell, matching: find.byType(GestureDetector)));

    // 수정 상태 확인
    expect(stateManager!.isEditing, true);

    // TODO : 셀 값 변경 (1) 안되서 (2) 강제로
    // (1)
    // await tester.pump(Duration(milliseconds:800));
    //
    // await tester.enterText(
    //     find.descendant(of: firstCell, matching: find.byType(TextField)),
    //     'cell value4');
    // (2)
    stateManager!
        .changeCellValue(stateManager!.currentCell!, 'header0 value 4');

    // 다음 행으로 이동
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);

    expect(rows[0].cells['header0']!.value, 'header0 value 4');
    expect(rows[1].cells['header0']!.value, 'header0 value 1');
    expect(rows[2].cells['header0']!.value, 'header0 value 2');

    Finder headerInkWell = find.descendant(
        of: find.byKey(columns.first.key), matching: find.byType(InkWell));

    await tester.tap(headerInkWell);
    // Ascending
    expect(rows[0].cells['header0']!.value, 'header0 value 1');
    expect(rows[1].cells['header0']!.value, 'header0 value 2');
    expect(rows[2].cells['header0']!.value, 'header0 value 4');

    await tester.tap(headerInkWell);
    // Descending
    expect(rows[0].cells['header0']!.value, 'header0 value 4');
    expect(rows[1].cells['header0']!.value, 'header0 value 2');
    expect(rows[2].cells['header0']!.value, 'header0 value 1');

    await tester.tap(headerInkWell);
    // Original
    expect(rows[0].cells['header0']!.value, 'header0 value 4');
    expect(rows[1].cells['header0']!.value, 'header0 value 1');
    expect(rows[2].cells['header0']!.value, 'header0 value 2');
  });

  testWidgets(
      'WHEN selecting a specific cell without grid header'
      'THEN That cell should be selected.', (WidgetTester tester) async {
    // given
    final columns = [
      ...ColumnHelper.textColumn('header', count: 10),
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // when
    // first cell of first column
    Finder firstCell = find.byKey(rows.first.cells['header0']!.key);

    // select first cell
    await tester.tap(
        find.descendant(of: firstCell, matching: find.byType(GestureDetector)));

    Offset selectedCellOffset =
        tester.getCenter(find.byKey(rows[7].cells['header3']!.key));

    stateManager!.setCurrentSelectingPositionWithOffset(selectedCellOffset);

    // then
    expect(stateManager!.currentSelectingPosition!.rowIdx, 7);
    expect(stateManager!.currentSelectingPosition!.columnIdx, 3);
  });

  testWidgets(
      'WHEN selecting a specific cell with grid header'
      'THEN That cell should be selected.', (WidgetTester tester) async {
    // given
    final columns = [
      ...ColumnHelper.textColumn('header', count: 10),
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
            createHeader: (stateManager) => const Text('grid header'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // when
    // first cell of first column
    Finder firstCell = find.byKey(rows.first.cells['header0']!.key);

    // select first cell
    await tester.tap(
        find.descendant(of: firstCell, matching: find.byType(GestureDetector)));

    Offset selectedCellOffset =
        tester.getCenter(find.byKey(rows[5].cells['header3']!.key));

    stateManager!.setCurrentSelectingPositionWithOffset(selectedCellOffset);

    // then
    expect(stateManager!.currentSelectingPosition!.rowIdx, 5);
    expect(stateManager!.currentSelectingPosition!.columnIdx, 3);
  });

  group('applyColumnRowOnInit', () {
    testWidgets(
        'number column'
        'WHEN applyFormatOnInit value of Column is true(default value)'
        'THEN cell value of the column should be changed to format.',
        (WidgetTester tester) async {
      // given
      final columns = [
        PlutoColumn(
          title: 'header',
          field: 'header',
          type: PlutoColumnType.number(),
        ),
      ];

      final rows = [
        PlutoRow(cells: {'header': PlutoCell(value: 'not a number')}),
        PlutoRow(cells: {'header': PlutoCell(value: 12)}),
        PlutoRow(cells: {'header': PlutoCell(value: '12')}),
        PlutoRow(cells: {'header': PlutoCell(value: -10)}),
        PlutoRow(cells: {'header': PlutoCell(value: 1234567)}),
        PlutoRow(cells: {'header': PlutoCell(value: 12.12345)}),
      ];

      PlutoGridStateManager? stateManager;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // then
      expect(stateManager!.rows[0].cells['header']!.value, 0);
      expect(stateManager!.rows[1].cells['header']!.value, 12);
      expect(stateManager!.rows[2].cells['header']!.value, 12);
      expect(stateManager!.rows[3].cells['header']!.value, -10);
      expect(stateManager!.rows[4].cells['header']!.value, 1234567);
      expect(stateManager!.rows[5].cells['header']!.value, 12);
    });

    testWidgets(
        'number column'
        'WHEN applyFormatOnInit value of Column is false'
        'THEN cell value of the column should not be changed to format.',
        (WidgetTester tester) async {
      // given
      final columns = [
        PlutoColumn(
          title: 'header',
          field: 'header',
          type: PlutoColumnType.number(applyFormatOnInit: false),
        ),
      ];

      final rows = [
        PlutoRow(cells: {'header': PlutoCell(value: 'not a number')}),
        PlutoRow(cells: {'header': PlutoCell(value: 12)}),
        PlutoRow(cells: {'header': PlutoCell(value: '12')}),
        PlutoRow(cells: {'header': PlutoCell(value: -10)}),
        PlutoRow(cells: {'header': PlutoCell(value: 1234567)}),
        PlutoRow(cells: {'header': PlutoCell(value: 12.12345)}),
      ];

      PlutoGridStateManager? stateManager;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // then
      expect(stateManager!.rows[0].cells['header']!.value, 'not a number');
      expect(stateManager!.rows[1].cells['header']!.value, 12);
      expect(stateManager!.rows[2].cells['header']!.value, '12');
      expect(stateManager!.rows[3].cells['header']!.value, -10);
      expect(stateManager!.rows[4].cells['header']!.value, 1234567);
      expect(stateManager!.rows[5].cells['header']!.value, 12.12345);
    });

    testWidgets(
        'number column'
        'WHEN format allows prime numbers'
        'THEN cell value should be displayed as a decimal number according to the number of digits in the format.',
        (WidgetTester tester) async {
      // given
      final columns = [
        PlutoColumn(
          title: 'header',
          field: 'header',
          type: PlutoColumnType.number(format: '#,###.#####'),
        ),
      ];

      final rows = [
        PlutoRow(cells: {'header': PlutoCell(value: 1234567)}),
        PlutoRow(cells: {'header': PlutoCell(value: 1234567.1234)}),
        PlutoRow(cells: {'header': PlutoCell(value: 1234567.12345)}),
        PlutoRow(cells: {'header': PlutoCell(value: 1234567.123456)}),
      ];

      PlutoGridStateManager? stateManager;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // then
      expect(stateManager!.rows[0].cells['header']!.value, 1234567);
      expect(stateManager!.rows[1].cells['header']!.value, 1234567.1234);
      expect(stateManager!.rows[2].cells['header']!.value, 1234567.12345);
      expect(stateManager!.rows[3].cells['header']!.value, 1234567.12346);
    });

    testWidgets(
        'number column'
        'WHEN negative is false'
        'THEN negative numbers should not be displayed in the cell value.',
        (WidgetTester tester) async {
      // given
      final columns = [
        PlutoColumn(
          title: 'header',
          field: 'header',
          type: PlutoColumnType.number(negative: false),
        ),
      ];

      final rows = [
        PlutoRow(cells: {'header': PlutoCell(value: 12345)}),
        PlutoRow(cells: {'header': PlutoCell(value: -12345)}),
        PlutoRow(cells: {'header': PlutoCell(value: 333.333)}),
        PlutoRow(cells: {'header': PlutoCell(value: -333.333)}),
        PlutoRow(cells: {'header': PlutoCell(value: 0)}),
        PlutoRow(cells: {'header': PlutoCell(value: -0)}),
      ];

      PlutoGridStateManager? stateManager;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // then
      expect(stateManager!.rows[0].cells['header']!.value, 12345);
      expect(stateManager!.rows[1].cells['header']!.value, 0);
      expect(stateManager!.rows[2].cells['header']!.value, 333);
      expect(stateManager!.rows[3].cells['header']!.value, 0);
      expect(stateManager!.rows[4].cells['header']!.value, 0);
      expect(stateManager!.rows[5].cells['header']!.value, 0);
    });

    testWidgets(
        'WHEN Row does not have sortIdx'
        'THEN sortIdx must be set in Row', (WidgetTester tester) async {
      // given
      final columns = [
        ...ColumnHelper.textColumn('header', count: 1),
      ];
      final rows = [
        PlutoRow(cells: {'header0': PlutoCell(value: 'value')}),
        PlutoRow(cells: {'header0': PlutoCell(value: 'value')}),
        PlutoRow(cells: {'header0': PlutoCell(value: 'value')}),
        PlutoRow(cells: {'header0': PlutoCell(value: 'value')}),
        PlutoRow(cells: {'header0': PlutoCell(value: 'value')}),
      ];

      PlutoGridStateManager? stateManager;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
              createHeader: (stateManager) => const Text('grid header'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // then
      expect(stateManager!.rows[0].sortIdx, 0);
      expect(stateManager!.rows[1].sortIdx, 1);
      expect(stateManager!.rows[2].sortIdx, 2);
      expect(stateManager!.rows[3].sortIdx, 3);
      expect(stateManager!.rows[4].sortIdx, 4);
    });

    testWidgets(
        'WHEN Row has sortIdx'
        'THEN sortIdx is not changed', (WidgetTester tester) async {
      // given
      final columns = [
        ...ColumnHelper.textColumn('header', count: 1),
      ];
      final rows = [
        PlutoRow(sortIdx: 5, cells: {'header0': PlutoCell(value: 'value')}),
        PlutoRow(sortIdx: 6, cells: {'header0': PlutoCell(value: 'value')}),
        PlutoRow(sortIdx: 7, cells: {'header0': PlutoCell(value: 'value')}),
        PlutoRow(sortIdx: 8, cells: {'header0': PlutoCell(value: 'value')}),
        PlutoRow(sortIdx: 9, cells: {'header0': PlutoCell(value: 'value')}),
      ];

      PlutoGridStateManager? stateManager;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
              createHeader: (stateManager) => const Text('grid header'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // then
      expect(stateManager!.rows[0].sortIdx, 5);
      expect(stateManager!.rows[1].sortIdx, 6);
      expect(stateManager!.rows[2].sortIdx, 7);
      expect(stateManager!.rows[3].sortIdx, 8);
      expect(stateManager!.rows[4].sortIdx, 9);
    });
  });

  group('moveColumn', () {
    testWidgets(
        '고정 컬럼이 없는 상태에서 '
        '0번 컬럼을 2번 컬럼으로 이동.', (WidgetTester tester) async {
      // given
      List<PlutoColumn> columns = [
        ...ColumnHelper.textColumn('body', count: 10, width: 100),
      ];

      List<PlutoRow> rows = RowHelper.count(10, columns);

      PlutoGridStateManager? stateManager;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // when
      stateManager!.moveColumn(column: columns[0], targetColumn: columns[2]);

      // then
      expect(columns[0].title, 'body1');
      expect(columns[1].title, 'body2');
      expect(columns[2].title, 'body0');
    });

    testWidgets(
        '고정 컬럼이 없는 상태에서 '
        '9번 컬럼을 0번 컬럼으로 이동.', (WidgetTester tester) async {
      // given
      List<PlutoColumn> columns = [
        ...ColumnHelper.textColumn('body', count: 10, width: 100),
      ];

      List<PlutoRow> rows = RowHelper.count(10, columns);

      PlutoGridStateManager? stateManager;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: PlutoGrid(
              columns: columns,
              rows: rows,
              onLoaded: (PlutoGridOnLoadedEvent event) {
                stateManager = event.stateManager;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // when
      stateManager!.moveColumn(column: columns[9], targetColumn: columns[0]);

      // then
      expect(columns[0].title, 'body9');
      expect(columns[1].title, 'body0');
      expect(columns[2].title, 'body1');
      expect(columns[3].title, 'body2');
      expect(columns[4].title, 'body3');
      expect(columns[5].title, 'body4');
      expect(columns[6].title, 'body5');
      expect(columns[7].title, 'body6');
      expect(columns[8].title, 'body7');
      expect(columns[9].title, 'body8');
    });

    testWidgets('넓이가 충분하지 않은 상태에서 고정 컬럼으로 설정하면 설정 되지 않아야 한다.',
        (WidgetTester tester) async {
      // given
      List<PlutoColumn> columns = [
        ...ColumnHelper.textColumn('body', count: 10, width: 100),
      ];

      List<PlutoRow> rows = RowHelper.count(10, columns);

      PlutoGridStateManager? stateManager;

      // when
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: SizedBox(
              width: 50,
              child: PlutoGrid(
                columns: columns,
                rows: rows,
                onLoaded: (PlutoGridOnLoadedEvent event) {
                  stateManager = event.stateManager;
                },
              ),
            ),
          ),
        ),
      );

      stateManager!
          .setLayout(const BoxConstraints(maxWidth: 50, maxHeight: 300));

      // when
      stateManager!.toggleFrozenColumn(columns[3], PlutoColumnFrozen.start);

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // then
      expect(columns[0].title, 'body0');
      expect(columns[1].title, 'body1');
      expect(columns[2].title, 'body2');
      expect(columns[3].title, 'body3');
      expect(columns[3].frozen, PlutoColumnFrozen.none);
      expect(columns[4].title, 'body4');
      expect(columns[5].title, 'body5');
      expect(columns[6].title, 'body6');
      expect(columns[7].title, 'body7');
      expect(columns[8].title, 'body8');
      expect(columns[9].title, 'body9');
    });
  });

  testWidgets('editing 상태에서 shift + 우측 방향키 입력 시 셀이 선택 되지 않아야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = [
      ColumnHelper.textColumn('headerL', frozen: PlutoColumnFrozen.start).first,
      ...ColumnHelper.textColumn('headerB', count: 3),
      ColumnHelper.textColumn('headerR', frozen: PlutoColumnFrozen.end).first,
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1 번 컬럼의 1번 행의 셀 선택
    Finder currentCell = find.text('headerB1 value 1');

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    // editing true
    expect(stateManager!.isEditing, false);

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    expect(stateManager!.isEditing, true);

    // 쉬프트 + 우측 키 입력
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');
    // editing 상태에서 shift + 방향키 입력 시 셀이 선택 되지 않아야 한다.
    expect(stateManager!.currentSelectingPosition, null);
    // 이동도 되지 않아야 한다.
    expect(stateManager!.currentCellPosition!.columnIdx, 2);
    expect(stateManager!.currentCellPosition!.rowIdx, 1);
  });

  testWidgets('editing 상태에서 shift + 좌측 방향키 입력 시 셀이 선택 되지 않아야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = [
      ColumnHelper.textColumn('headerL', frozen: PlutoColumnFrozen.start).first,
      ...ColumnHelper.textColumn('headerB', count: 3),
      ColumnHelper.textColumn('headerR', frozen: PlutoColumnFrozen.end).first,
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1 번 컬럼의 1번 행의 셀 선택
    Finder currentCell = find.text('headerB1 value 1');

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    // editing true
    expect(stateManager!.isEditing, false);

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    expect(stateManager!.isEditing, true);

    // 쉬프트 + 우측 키 입력
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');
    // editing 상태에서 shift + 방향키 입력 시 셀이 선택 되지 않아야 한다.
    expect(stateManager!.currentSelectingPosition, null);
    // 이동도 되지 않아야 한다.
    expect(stateManager!.currentCellPosition!.columnIdx, 2);
    expect(stateManager!.currentCellPosition!.rowIdx, 1);
  });

  testWidgets('editing 상태에서 shift + 위쪽 방향키 입력 시 셀이 선택 되지 않아야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = [
      ColumnHelper.textColumn('headerL', frozen: PlutoColumnFrozen.start).first,
      ...ColumnHelper.textColumn('headerB', count: 3),
      ColumnHelper.textColumn('headerR', frozen: PlutoColumnFrozen.end).first,
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1 번 컬럼의 1번 행의 셀 선택
    Finder currentCell = find.text('headerB1 value 1');

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    // editing true
    expect(stateManager!.isEditing, false);

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    expect(stateManager!.isEditing, true);

    // 쉬프트 + 우측 키 입력
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');
    // editing 상태에서 shift + 방향키 입력 시 셀이 선택 되지 않아야 한다.
    expect(stateManager!.currentSelectingPosition, null);
    // 이동도 되지 않아야 한다.
    expect(stateManager!.currentCellPosition!.columnIdx, 2);
    expect(stateManager!.currentCellPosition!.rowIdx, 1);
  });

  testWidgets('editing 상태에서 shift + 아래쪽 방향키 입력 시 셀이 선택 되지 않아야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = [
      ColumnHelper.textColumn('headerL', frozen: PlutoColumnFrozen.start).first,
      ...ColumnHelper.textColumn('headerB', count: 3),
      ColumnHelper.textColumn('headerR', frozen: PlutoColumnFrozen.end).first,
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1 번 컬럼의 1번 행의 셀 선택
    Finder currentCell = find.text('headerB1 value 1');

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    // editing true
    expect(stateManager!.isEditing, false);

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    expect(stateManager!.isEditing, true);

    // 쉬프트 + 우측 키 입력
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');
    // editing 상태에서 shift + 방향키 입력 시 셀이 선택 되지 않아야 한다.
    expect(stateManager!.currentSelectingPosition, null);
    // 이동도 되지 않아야 한다.
    expect(stateManager!.currentCellPosition!.columnIdx, 2);
    expect(stateManager!.currentCellPosition!.rowIdx, 1);
  });

  testWidgets('editing 상태가 아니면, shift + 우측 방향키 입력 시 셀이 선택 되어야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = [
      ColumnHelper.textColumn('headerL', frozen: PlutoColumnFrozen.start).first,
      ...ColumnHelper.textColumn('headerB', count: 3),
      ColumnHelper.textColumn('headerR', frozen: PlutoColumnFrozen.end).first,
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1 번 컬럼의 1번 행의 셀 선택
    Finder currentCell = find.text('headerB1 value 1');

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    // editing true
    expect(stateManager!.isEditing, false);

    // 쉬프트 + 우측 키 입력
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

    await tester.pumpAndSettle();

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');
    // editing 상태가 아니면 shift + 방향키 입력 시 셀이 선택 되어야 한다.
    expect(stateManager!.currentSelectingPosition!.columnIdx, 3);
    expect(stateManager!.currentSelectingPosition!.rowIdx, 1);
    // 현재 선택 셀은 이동 되지 않아야 한다.
    expect(stateManager!.currentCellPosition!.columnIdx, 2);
    expect(stateManager!.currentCellPosition!.rowIdx, 1);
  });

  testWidgets('editing 상태가 아니면, shift + 좌측 방향키 입력 시 셀이 선택 되어야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = [
      ColumnHelper.textColumn('headerL', frozen: PlutoColumnFrozen.start).first,
      ...ColumnHelper.textColumn('headerB', count: 3),
      ColumnHelper.textColumn('headerR', frozen: PlutoColumnFrozen.end).first,
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1 번 컬럼의 1번 행의 셀 선택
    Finder currentCell = find.text('headerB1 value 1');

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    // editing true
    expect(stateManager!.isEditing, false);

    // 쉬프트 + 우측 키 입력
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');
    // editing 상태가 아니면 shift + 방향키 입력 시 셀이 선택 되어야 한다.
    expect(stateManager!.currentSelectingPosition!.columnIdx, 1);
    expect(stateManager!.currentSelectingPosition!.rowIdx, 1);
    // 현재 선택 셀은 이동 되지 않아야 한다.
    expect(stateManager!.currentCellPosition!.columnIdx, 2);
    expect(stateManager!.currentCellPosition!.rowIdx, 1);
  });

  testWidgets('editing 상태가 아니면, shift + 위쪽 방향키 입력 시 셀이 선택 되어야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = [
      ColumnHelper.textColumn('headerL', frozen: PlutoColumnFrozen.start).first,
      ...ColumnHelper.textColumn('headerB', count: 3),
      ColumnHelper.textColumn('headerR', frozen: PlutoColumnFrozen.end).first,
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1 번 컬럼의 1번 행의 셀 선택
    Finder currentCell = find.text('headerB1 value 1');

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    // editing true
    expect(stateManager!.isEditing, false);

    // 쉬프트 + 우측 키 입력
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');
    // editing 상태가 아니면 shift + 방향키 입력 시 셀이 선택 되어야 한다.
    expect(stateManager!.currentSelectingPosition!.columnIdx, 2);
    expect(stateManager!.currentSelectingPosition!.rowIdx, 0);
    // 현재 선택 셀은 이동 되지 않아야 한다.
    expect(stateManager!.currentCellPosition!.columnIdx, 2);
    expect(stateManager!.currentCellPosition!.rowIdx, 1);
  });

  testWidgets('editing 상태가 아니면, shift + 아래쪽 방향키 입력 시 셀이 선택 되어야 한다.',
      (WidgetTester tester) async {
    // given
    final columns = [
      ColumnHelper.textColumn('headerL', frozen: PlutoColumnFrozen.start).first,
      ...ColumnHelper.textColumn('headerB', count: 3),
      ColumnHelper.textColumn('headerR', frozen: PlutoColumnFrozen.end).first,
    ];
    final rows = RowHelper.count(10, columns);

    PlutoGridStateManager? stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1 번 컬럼의 1번 행의 셀 선택
    Finder currentCell = find.text('headerB1 value 1');

    await tester.tap(currentCell);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');

    // editing true
    expect(stateManager!.isEditing, false);

    // 쉬프트 + 우측 키 입력
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);

    expect(stateManager!.currentCell!.value, 'headerB1 value 1');
    // editing 상태가 아니면 shift + 방향키 입력 시 셀이 선택 되어야 한다.
    expect(stateManager!.currentSelectingPosition!.columnIdx, 2);
    expect(stateManager!.currentSelectingPosition!.rowIdx, 2);
    // 현재 선택 셀은 이동 되지 않아야 한다.
    expect(stateManager!.currentCellPosition!.columnIdx, 2);
    expect(stateManager!.currentCellPosition!.rowIdx, 1);
  });

  testWidgets('showLoading 을 호출 하면 Loading 위젯이 나타나야 한다.', (tester) async {
    final columns = ColumnHelper.textColumn('column', count: 10);
    final rows = RowHelper.count(10, columns);

    late final PlutoGridStateManager stateManager;

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;
            },
          ),
        ),
      ),
    );

    stateManager.setShowLoading(true);

    await tester.pump();

    expect(find.byType(PlutoLoading), findsOneWidget);
  });

  testWidgets('showLoading 을 호출 하지 않으면 Loading 위젯이 나타나지 않아야 한다.',
      (tester) async {
    final columns = ColumnHelper.textColumn('column', count: 10);
    final rows = RowHelper.count(10, columns);

    // when
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: PlutoGrid(
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(PlutoLoading), findsNothing);
  });

  testWidgets(
    '생성자를 호출 할 수 있어야 한다.',
    (WidgetTester tester) async {
      final PlutoGridOnChangedEvent onChangedEvent = PlutoGridOnChangedEvent(
        columnIdx: null,
        rowIdx: 1,
      );

      expect(onChangedEvent.columnIdx, null);
      expect(onChangedEvent.rowIdx, 1);
    },
  );
}

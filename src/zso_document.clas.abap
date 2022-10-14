CLASS zso_document DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF t_data,
        file_name    TYPE string,
        data_xstring TYPE xstring,
      END OF t_data.


    CLASS-METHODS get_so_document
      IMPORTING document_id        TYPE sofolenti1-doc_id
      RETURNING VALUE(so_document) TYPE REF TO zso_document .

    METHODS get_data
      RETURNING VALUE(document_data) TYPE t_data
      RAISING   zcx_return3.

    METHODS get_data_xstring
      RETURNING VALUE(data_xstring) TYPE xstring
      RAISING   zcx_return3.

    METHODS get_file_name
      RETURNING VALUE(file_name) TYPE string
      RAISING   zcx_return3.

  PROTECTED SECTION.

  PRIVATE SECTION.

    DATA document_id TYPE sofolenti1-doc_id.

    METHODS _get_file_name
      IMPORTING
        !object_header_tab TYPE swftlisti1
        !document_data     TYPE sofolenti1
      RETURNING
        VALUE(file_name)   TYPE string .

    TYPES:
      t_solisti1_tab TYPE STANDARD TABLE OF solisti1 WITH DEFAULT KEY .

    METHODS _convert_solisti1_tab_to_xstr
      IMPORTING !solisti1_tab       TYPE t_solisti1_tab
                !text_length        TYPE i
      RETURNING VALUE(data_xstring) TYPE xstring
      RAISING
                zcx_return3 .

ENDCLASS.



CLASS ZSO_DOCUMENT IMPLEMENTATION.


  METHOD get_data.

    "------------------------------------------
    "Read attachment binary SOLIX
    "------------------------------------------
    DATA:
      so_document_data   TYPE sofolenti1,
      object_header_tab  TYPE TABLE OF solisti1,
      object_content_tab TYPE TABLE OF solisti1,
      contents_solix_tab TYPE TABLE OF solix.

    CLEAR document_data.
    REFRESH object_header_tab.
    REFRESH object_content_tab.
    REFRESH contents_solix_tab.

    CALL FUNCTION 'SO_DOCUMENT_READ_API1'
      EXPORTING
        document_id    = document_id
*       filter         = ls_filter  "TODO delete
      IMPORTING
        document_data  = so_document_data
      TABLES
        object_header  = object_header_tab
        object_content = object_content_tab
        contents_hex   = contents_solix_tab
      EXCEPTIONS
        OTHERS         = 0.

    document_data-file_name =
      _get_file_name(
        object_header_tab = object_header_tab[]
        document_data     = so_document_data ).

    "------------------------------------------
    "Append to output
    "------------------------------------------
    IF contents_solix_tab[] IS NOT INITIAL.

      CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
        EXPORTING
          input_length = CONV i( so_document_data-doc_size )
        IMPORTING
          buffer       = document_data-data_xstring
        TABLES
          binary_tab   = contents_solix_tab
        EXCEPTIONS
          failed       = 1
          OTHERS       = 2.

      IF sy-subrc <> 0.
        RAISE EXCEPTION TYPE zcx_return3
          USING MESSAGE.
      ENDIF.

    ELSE.

      document_data-data_xstring =
        _convert_solisti1_tab_to_xstr(
          solisti1_tab        = object_content_tab
          text_length         = CONV #( so_document_data-doc_size ) ).

    ENDIF.

  ENDMETHOD.


  METHOD get_data_xstring.

    DATA(document_data) = me->get_data( ).

    data_xstring = document_data-data_xstring.

  ENDMETHOD.


  METHOD get_file_name.

    DATA(document_data) = me->get_data( ).

    file_name = document_data-file_name.

  ENDMETHOD.


  METHOD get_so_document.

    so_document = NEW zso_document( ).

    so_document->document_id = document_id.

  ENDMETHOD.


  METHOD _convert_solisti1_tab_to_xstr.

    "--------------------------------------
    "Convert to SOLI_TAB
    "--------------------------------------
    DATA(solisti1_tab_line_count) = lines( solisti1_tab ).

    DATA soli_tab TYPE soli_tab.
    DATA text_size TYPE i.

    LOOP AT solisti1_tab
      ASSIGNING FIELD-SYMBOL(<solist>).

      IF sy-tabix < solisti1_tab_line_count.
        text_size = text_size + 255.
      ELSE.
        text_size = text_size + strlen( <solist>-line ).
      ENDIF.

      APPEND INITIAL LINE TO soli_tab
        ASSIGNING FIELD-SYMBOL(<soli>).

      <soli>-line = <solist>-line.

    ENDLOOP.

    TRY.

        data_xstring =
         cl_bcs_convert=>txt_to_xstring(
           it_soli     = soli_tab
           iv_size     = text_size ).

      CATCH cx_bcs INTO DATA(bcs_exc).

        DATA(return_exc) = NEW zcx_return3( ).
        return_exc->add_exception_object( bcs_exc ).
        RAISE EXCEPTION return_exc.

    ENDTRY.

  ENDMETHOD.


  METHOD _get_file_name.

    LOOP AT object_header_tab
      ASSIGNING FIELD-SYMBOL(<object_header>).

      DATA length_13_text TYPE c LENGTH 13.
      length_13_text = <object_header>.

      IF length_13_text = '&SO_FILENAME='.

        file_name = <object_header>+13.
        RETURN.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.
ENDCLASS.

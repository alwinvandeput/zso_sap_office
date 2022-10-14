CLASS unit_test DEFINITION FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    METHODS: get_data FOR TESTING.

ENDCLASS.       "unit_Test


CLASS unit_test IMPLEMENTATION.

  METHOD get_data.

    TRY.

        DATA(document_id) = CONV sofolenti1-doc_id( 'TODO document_id' ).

        DATA(so_document) = zso_document=>get_so_document( document_id ).

        DATA(document_data) = so_document->get_data( ).

        cl_abap_unit_assert=>assert_not_initial(
          act = document_data ).

        DATA(file_name) = so_document->get_file_name( ).

        cl_abap_unit_assert=>assert_not_initial(
          act = file_name ).

      CATCH zcx_return3 INTO DATA(return3_exc).

        cl_abap_unit_assert=>fail(
          msg    = return3_exc->get_text( ) ).

    ENDTRY.

  ENDMETHOD.

ENDCLASS.

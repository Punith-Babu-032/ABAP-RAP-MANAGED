CLASS lcl_save DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lcl_save IMPLEMENTATION.

  METHOD save_modified.

    DATA lt_booksuppl_db TYPE STANDARD TABLE OF /dmo/booksuppl_m.

    " (1) Get instance data of all instances that have been created
    IF create-booksuppl IS NOT INITIAL.
      lt_booksuppl_db = CORRESPONDING #( create-booksuppl ).

      CALL FUNCTION '/DMO/FLIGHT_BOOKSUPPL_C' EXPORTING values = lt_booksuppl_db .

    ENDIF.

    " (2) Get instance data of all instances that have been updated during the transaction
    IF update-booksuppl IS NOT INITIAL.
      lt_booksuppl_db = CORRESPONDING #( update-booksuppl ).

      " Read all field values from database
      SELECT * FROM /dmo/booksuppl_m FOR ALL ENTRIES IN @lt_booksuppl_db
               WHERE booking_supplement_id = @lt_booksuppl_db-booking_supplement_id
               INTO TABLE @lt_booksuppl_db .

      " Take over field values that have been changed during the transaction
      LOOP AT update-booksuppl ASSIGNING FIELD-SYMBOL(<ls_unmanaged_booksuppl>).
        ASSIGN lt_booksuppl_db[ travel_id  = <ls_unmanaged_booksuppl>-travel_id
                                booking_id = <ls_unmanaged_booksuppl>-booking_id
                     booking_supplement_id = <ls_unmanaged_booksuppl>-booking_supplement_id
                       ] TO FIELD-SYMBOL(<ls_booksuppl_db>).

        IF <ls_unmanaged_booksuppl>-%control-supplement_id = if_abap_behv=>mk-on.
          <ls_booksuppl_db>-supplement_id = <ls_unmanaged_booksuppl>-supplement_id.
        ENDIF.

        IF <ls_unmanaged_booksuppl>-%control-price = if_abap_behv=>mk-on.
          <ls_booksuppl_db>-price = <ls_unmanaged_booksuppl>-price.
        ENDIF.

        IF <ls_unmanaged_booksuppl>-%control-currency_code = if_abap_behv=>mk-on.
          <ls_booksuppl_db>-currency_code = <ls_unmanaged_booksuppl>-currency_code.
        ENDIF.

      ENDLOOP.

      " Update the complete instance data
      CALL FUNCTION '/DMO/FLIGHT_BOOKSUPPL_U' EXPORTING values = lt_booksuppl_db .

    ENDIF.

    " (3) Get keys of all travel instances that have been deleted during the transaction
    IF delete-booksuppl IS NOT INITIAL.
      lt_booksuppl_db = CORRESPONDING #( delete-booksuppl ).

      CALL FUNCTION '/DMO/FLIGHT_BOOKSUPPL_D' EXPORTING values = lt_booksuppl_db .

    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_features FOR FEATURES IMPORTING keys REQUEST requested_features FOR booksuppl RESULT result.
    METHODS calculate_total_price FOR DETERMINATION booksuppl~calculateTotalSupplmPrice
      IMPORTING keys FOR booksuppl.

ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.

  METHOD get_features.

    READ ENTITIES OF zi_cds_travel_m IN LOCAL MODE
      ENTITY booksuppl
         FIELDS ( booking_supplement_id )
           WITH VALUE #( FOR keyval IN keys ( %tky = keyval-%tky ) )
         RESULT  DATA(lt_booksupppl_result).


    result = VALUE #( FOR ls_travel IN lt_booksupppl_result
                       ( %tky                         = ls_travel-%tky
                         %field-booking_supplement_id = if_abap_behv=>fc-f-read_only
                        ) ).

  ENDMETHOD.

  METHOD calculate_total_price.

    IF keys IS NOT INITIAL.
      zcl_travel_auxiliary_m=>calculate_price(
          it_travel_id = VALUE #(  FOR GROUPS <booking_suppl> OF booksuppl_key IN keys
                                       GROUP BY booksuppl_key-travel_id WITHOUT MEMBERS
                                             ( <booking_suppl> ) ) ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.

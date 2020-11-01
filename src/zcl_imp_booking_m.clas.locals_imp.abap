CLASS lhc_travel DEFINITION INHERITING FROM cl_abap_behavior_handler.

PRIVATE SECTION.
METHODS get_features FOR FEATURES IMPORTING keys REQUEST requested_features FOR booking RESULT result.
METHODS validate_booking_status  FOR VALIDATE ON SAVE importing keys FOR booking~validateStatus.
METHODS calculate_total_flight_price FOR DETERMINATION booking~calculateTotalFlightPrice
        IMPORTING keys FOR booking.

ENDCLASS.

CLASS lhc_travel IMPLEMENTATION.


  METHOD get_features.
    READ ENTITIES OF zi_cds_travel_m IN LOCAL MODE
      ENTITY booking
         FIELDS ( booking_id booking_status )
         WITH CORRESPONDING #( keys )
      RESULT    DATA(lt_booking_result).

    result = VALUE #( FOR ls_travel IN lt_booking_result
                       ( %key                   = ls_travel-%key
                         %field-booking_id      = if_abap_behv=>fc-f-read_only
                         %field-booking_date    = if_abap_behv=>fc-f-read_only
                         %field-customer_id     = if_abap_behv=>fc-f-read_only
                         %assoc-_BookSupplement = COND #( WHEN ls_travel-booking_status = 'B'
                                                          THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
                         "%features-%delete   = if_abap_behv=>fc-o-disabled  " Workaround for missing determinations OnDelete
                      ) ).

  ENDMETHOD.

  METHOD validate_booking_status.
    READ ENTITIES OF zi_cds_travel_m IN LOCAL MODE
      ENTITY  booking
        FIELDS ( booking_status )
        WITH CORRESPONDING #( keys )
      RESULT DATA(lt_booking_result).

    LOOP AT lt_booking_result INTO DATA(ls_booking_result).
      CASE ls_booking_result-booking_status.
        WHEN 'N'.  " New
        WHEN 'X'.  " Canceled
        WHEN 'B'.  " Booked
        WHEN OTHERS.
          APPEND VALUE #( %key = ls_booking_result-%key ) TO failed-travel.

          APPEND VALUE #( %key = ls_booking_result-%key
                          %msg = new_message( id       = /dmo/cx_flight_legacy=>status_is_not_valid-msgid
                                              number   = /dmo/cx_flight_legacy=>status_is_not_valid-msgno
                                              v1       = ls_booking_result-booking_status
                                              severity = if_abap_behv_message=>severity-error )
                          %element-booking_status = if_abap_behv=>mk-on ) TO reported-booking.
      ENDCASE.

    ENDLOOP.

  ENDMETHOD.

  METHOD calculate_total_flight_price.

    IF keys IS NOT INITIAL.
      zcl_travel_auxiliary_m=>calculate_price(
          it_travel_id = VALUE #(  FOR GROUPS <booking> OF booking_key IN keys
                                       GROUP BY booking_key-travel_id WITHOUT MEMBERS
                                             ( <booking> ) ) ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.

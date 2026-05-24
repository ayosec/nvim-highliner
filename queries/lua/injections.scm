; extends

((function_call
  name: _ @_highliner_identifier
  arguments: (arguments
    (table_constructor
      (field
        name: _ @_highliner_field
        value: (string content: _ @injection.content))))
  )

  (#eq? @_highliner_identifier "highliner.add")
  (#eq? @_highliner_field "query")
  (#set! injection.language "query")
)

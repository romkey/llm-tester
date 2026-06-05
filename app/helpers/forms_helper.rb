# frozen_string_literal: true

module FormsHelper
  def form_label_with_requirement(form, attribute, text: nil, required: false, optional: false, hint: nil)
    label_text = text || form.object.class.human_attribute_name(attribute)

    safe_join([
      form.label(attribute, class: "form-label") {
        safe_join([ label_text, field_requirement_badge(required: required, optional: optional) ].compact, " ")
      },
      (tag.p(hint, class: "form-text") if hint.present?)
    ].compact)
  end

  def form_check_label_with_requirement(form, attribute, text:, optional: false, hint: nil, check_box_options: {})
    check_box_options = { class: "form-check-input" }.merge(check_box_options)

    safe_join([
      tag.div(class: "form-check") {
        safe_join([
          form.check_box(attribute, check_box_options),
          form.label(attribute, class: "form-check-label") {
            safe_join([ text, field_requirement_badge(optional: optional) ].compact, " ")
          }
        ])
      },
      (tag.p(hint, class: "form-text") if hint.present?)
    ].compact)
  end

  def field_requirement_badge(required: false, optional: false)
    if required
      tag.span("Required", class: "badge rounded-pill text-bg-danger ms-1 align-middle fw-normal")
    elsif optional
      tag.span("Optional", class: "badge rounded-pill text-bg-secondary ms-1 align-middle fw-normal")
    end
  end
end

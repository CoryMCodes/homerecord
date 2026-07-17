class Ui::ButtonComponent < ApplicationComponent
  VARIANT_CLASSES = {
    primary: "bg-primary text-primary-foreground shadow-floating hover:bg-primary-hover",
    secondary: "bg-card text-foreground shadow-card ring-1 ring-border hover:bg-primary-soft",
    ghost: "text-muted-foreground hover:bg-primary-soft hover:text-foreground"
  }.freeze

  SIZE_CLASSES = {
    sm: "px-3 py-1.5 text-sm",
    md: "px-4 py-2.5 text-sm",
    icon: "size-11 justify-center text-lg"
  }.freeze

  attr_reader :href, :type, :disabled

  def initialize(href: nil, variant: :primary, size: :md, type: "button", disabled: false)
    @href = href
    @variant = variant.to_sym
    @size = size.to_sym
    @type = type
    @disabled = disabled

    raise ArgumentError, "unknown button variant: #{variant}" unless VARIANT_CLASSES.key?(@variant)
    raise ArgumentError, "unknown button size: #{size}" unless SIZE_CLASSES.key?(@size)
  end

  def classes
    [
      "inline-flex items-center justify-center gap-2 rounded-full font-semibold",
      "transition-[background-color,box-shadow,transform] duration-200 motion-reduce:transition-none",
      "disabled:pointer-events-none disabled:opacity-50",
      ("pointer-events-none opacity-50" if disabled),
      VARIANT_CLASSES.fetch(@variant),
      SIZE_CLASSES.fetch(@size)
    ].compact.join(" ")
  end
end

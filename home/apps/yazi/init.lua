-- Adaptive layout based on terminal width
-- Breakpoints tuned to Hyprland half/quarter splits:
--   ~37 cols (quarter), ~80 cols (half), ~129 cols (three-quarter)

local tab_layout = Tab.layout

function Tab:layout()
    tab_layout(self)

    local w = self._area.w
    local ratio
    if w < 40 then
        ratio = { 0, 1, 0 }
    elseif w < 60 then
        ratio = { 1, 3, 0 }
    elseif w < 110 then
        ratio = { 1, 3, 2 }
    else
        ratio = { 1, 4, 3 }
    end

    local all = ratio[1] + ratio[2] + ratio[3]
    self._chunks = ui.Layout()
        :direction(ui.Layout.HORIZONTAL)
        :constraints({
            ui.Constraint.Ratio(ratio[1], all),
            ui.Constraint.Ratio(ratio[2], all),
            ui.Constraint.Ratio(ratio[3], all),
        })
        :split(self._area)
end

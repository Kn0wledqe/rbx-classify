--= Require Classify =--
local classify = require(script.Parent:WaitForChild('Classify'))

--= Class Root =--
local TestButton = { }
TestButton.__classname = 'TestingTextButton'

--= Properties =--
TestButton.__properties = {
    AnchorPoint = {
        bind = 'AnchorPoint',
        target = function(self) return self._instance end
    },
    Position = {
        bind = 'Position',
        target = function(self) return self._instance end
    },
    Text = {
        bind = 'Text',
        target = function(self) return self._instance end
    },
    Transparency = {
        get = function(self)
            return self._transparency
        end,
        set = function(self, value: number)
            self._transparency = value
            self._instance.BackgroundTransparency = value
            self._instance.TextTransparency = value
        end
    }
}

function TestButton:__cleaned()
    print('Waiting...')
    wait(2)
    print('Done!')
end

--= API =--
function TestButton:SetVisible(state: bool)
    self._instance.Visible = state
end

--= Constructor =--
function TestButton.new(parent: Instance)
    local self = classify(TestButton)
    
    local button = Instance.new('TextButton', parent)
    button.BackgroundColor3 = Color3.new(1, 1, 1)
    button.Size = UDim2.fromOffset(200, 50)
    button.Text = 'TestButton'
    
    self._transparency = 0
    self._instance = button
    self.Activated = button.Activated
    
    self:_mark_disposable(button)
    return self
end

--= Return Class =--
return TestButton

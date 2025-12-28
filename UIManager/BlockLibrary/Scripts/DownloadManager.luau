local DownloadManager = {}

local HttpService = game:GetService("HttpService")

type DownloadManagerState = "Install" | "Update"

local PS_KEY_DOWNLOADED = "Downloaded"


local StudioService = game:GetService("StudioService")

local function readFromPluginSettings(plugin: Plugin)
    local settings = plugin:GetSetting(PS_KEY_DOWNLOADED) or "{}"

    local settingsTable = HttpService:JSONDecode(settings)

    return settingsTable
end

local addPreview = require(script.Parent.BlockPreviewer)

function DownloadManager:Init(plugin, DownloadBlockPackUI, DowloadBlockPackBlocksUI, myPackagesUI,  UIManager, dataManager, FireStoreManager, refreshCallback)
    self.Plugin = plugin
    self.DownloadBlockPackUI = DownloadBlockPackUI
    self.DowloadBlockPackBlocksUI = DowloadBlockPackBlocksUI
    self.MyPackagesUI = myPackagesUI

    self.UIManager = UIManager
    self.FireStoreManager = FireStoreManager
    self.dataManager = dataManager

    self.CurrentBlockPack = nil
    self.State = "Install"
    self.CurrentBlockPackBlocks = {}

    self.DownloadBlockPackUI.Visible = false
    self.DowloadBlockPackBlocksUI.Visible = false

    self.refreshCallback = refreshCallback

    self.DownloadBlockPackUI.Install.MouseButton1Down:Connect(function()
        if #self.CurrentBlockPackBlocks == 0 then
            for _, blockId in ipairs(self.CurrentBlockPack.ContentBlockIds) do
                local block = self.dataManager:BlockDataById(blockId)
                if block then
                    table.insert(self.CurrentBlockPackBlocks, block)
                end
                
            end
        end

        local SaveData = readFromPluginSettings(plugin)

        local BlockSaveData = {
            BlockPack = self.CurrentBlockPack,
            Blocks = self.CurrentBlockPackBlocks,
            Enabled = true
            -- TODO: add creation date so we can check if the blocks update
        }

        SaveData[self.CurrentBlockPack.PackId] = BlockSaveData

        plugin:SetSetting(PS_KEY_DOWNLOADED, HttpService:JSONEncode(SaveData))

        -- set the button to update
        self.State = "Update"
        self.DownloadBlockPackUI.Install.Text = "Update"
        
        self.refreshCallback()
    end)


    self.DownloadBlockPackUI.SeeBlocks.MouseButton1Down:Connect(function()
        self.UIManager:appendView(self.DowloadBlockPackBlocksUI)

        for _, blockToDelet in pairs(self.DowloadBlockPackBlocksUI:GetChildren()) do
            if blockToDelet:IsA("ImageButton") and blockToDelet.Visible then
                blockToDelet:Destroy()
            end
        end

        if #self.CurrentBlockPackBlocks == 0 then
            warn(self.CurrentBlockPack.ContentBlockIds)
            for _, blockId in ipairs(self.CurrentBlockPack.ContentBlockIds) do
                local block = self.dataManager:BlockDataById(blockId)
                print(block)
                if block then
                    table.insert(self.CurrentBlockPackBlocks, block)
                else
                    warn("Block not found: " .. blockId)
                end
                
            end
        end
        
        for _, block in ipairs(self.CurrentBlockPackBlocks) do
            print(block.Name)
            local blockUI = self.DowloadBlockPackBlocksUI.Block:Clone()
            blockUI.Parent = self.DowloadBlockPackBlocksUI
            blockUI.TextContents.BlockName.Text = block.Name
            blockUI.TextContents.BlockDescription.Text = block.Description
            blockUI.Visible = true
            addPreview(blockUI.Preview, block, self.CurrentBlockPack.IconColor )

        end 
    end)    
end


function DownloadManager:PromptDownloadBlockPack(blockPack)
    self.UIManager:appendView(self.DownloadBlockPackUI)

    self.CurrentBlockPack = blockPack

    self.DownloadBlockPackUI.Title.Text = blockPack.Name
    self.DownloadBlockPackUI.Description.Text = blockPack.Description

    self.DownloadBlockPackUI.Preview.ImageColor3 = Color3.fromHex(blockPack.IconColor)
    self.DownloadBlockPackUI.Preview.TextLabel.Text = #blockPack.ContentBlockIds

    local packId = blockPack.PackId
    local isDownloaded = readFromPluginSettings(self.Plugin)[packId] 

    if blockPack.Creator == StudioService:GetUserId() and  blockPack.Creator ~= 2429357857 then
        self.DownloadBlockPackUI.Install.Visible = false
    else
        self.DownloadBlockPackUI.Install.Visible = true
    end

    if isDownloaded then
        self.State = "Update"
        self.DownloadBlockPackUI.Install.Text = "Update"
    else
        self.State = "Install"
        self.DownloadBlockPackUI.Install.Text = "Install"
    end
end

function DownloadManager:PromptMyPackages()
    self.UIManager:appendView(self.MyPackagesUI)

    local InstallData = readFromPluginSettings(self.Plugin)

    for _, blockToDelet in pairs(self.MyPackagesUI:GetChildren()) do
        if blockToDelet:IsA("ImageButton") and blockToDelet.Visible then
            blockToDelet:Destroy()
        end
    end

    for packID, blockContainer in pairs(InstallData ) do
        local blockPack = blockContainer.BlockPack
        local packButton = self.MyPackagesUI.Package:Clone()

        packButton.Parent = self.MyPackagesUI
        packButton.TextContents.PackName.Text = blockPack.Name
        packButton.TextContents.PackDescription.Text = blockPack.Description

        packButton.Preview.ImageColor3 = Color3.fromHex(blockPack.IconColor)
        packButton.Preview.TextLabel.Text = #blockPack.ContentBlockIds

        packButton.Buttons.Uninstall.MouseButton1Down:Connect(function()
            InstallData[packID] = nil
            self.Plugin:SetSetting(PS_KEY_DOWNLOADED, HttpService:JSONEncode(InstallData))

            packButton:Destroy()
            self.refreshCallback()
        end)

        packButton.Buttons.Switch.TextLabel.Text = InstallData[packID].Enabled and "Disable" or "Enable"

        packButton.Buttons.Switch.MouseButton1Down:Connect(function()
            InstallData[packID].Enabled = not InstallData[packID].Enabled
            self.Plugin:SetSetting(PS_KEY_DOWNLOADED, HttpService:JSONEncode(InstallData))

            packButton.Buttons.Switch.TextLabel.Text = InstallData[packID].Enabled and "Disable" or "Enable"

            -- Refresh the block list
            self.refreshCallback()
        end)
        
        packButton.Visible = true
    end
end


return DownloadManager
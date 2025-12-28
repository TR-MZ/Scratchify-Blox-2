local FireStoreManager = {}
local HttpService = game:GetService("HttpService")

export type AuthResult = {
	expiresIn : string,
	idToken: string,
	kind :  string,
	localId: string,
	refreshToken: string
}

export type Block = {
	Name: string,
	Description: string,
	Type: string,
	Elements : {{contentType: string, content: string}},
	Code: string,
	owner_id: string,
}


export type BlockPack = {
	Name: string,
	Description: string,
	IconColor: string, -- hex color
	ContentBlockIds: {string}, -- firebase references
	owner_id: string, -- LocalId of the owner (firebase auth user)
	Tag: string,
	Downloads: {}, -- List containing everyuser who stared the package
}


local API_KEY = "AIzaSyCXLxp2NVGOPZv9iofBptXxWtPQa4b8lp4"
local PROJECT_ID = "scratchifyblocks2"
local Auth: AuthResult & any
local plugin 

local UIManager, Ui

local function saveToken(auth: AuthResult)
	local expireTime = os.time()  + tonumber(auth.expiresIn)
	
	local save = {
		idToken = auth.idToken,
		expirationTime = expireTime,
		localId = auth.localId,
		refreshToken = auth.refreshToken
	} 
	
	plugin:SetSetting("Auth", HttpService:JSONEncode(save))
end

--- Function to attempt login with given credentials
local function tryLogin(password, email)
	local success, result = pcall(function()
		-- Replace with your actual Firebase/Firestore authentication endpoint
		local url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key="..API_KEY

		-- Prepare the login data
		local loginData = {
			email = email,
			password = password,
			returnSecureToken = true
		}


		-- Convert to JSON
		local jsonData = HttpService:JSONEncode(loginData)

		-- Make the request
		local response = HttpService:PostAsync(url, jsonData, Enum.HttpContentType.ApplicationJson)

		-- Parse the response
		return HttpService:JSONDecode(response)
	end)

	if success then
		return true, result
	else
		return false, "Failed to connect to authentication server: " .. tostring(result)
	end
end

-- Function to attempt account creation with given credentials
local function tryCreateAccount(password, email, displayName)
	local success, result = pcall(function()
		-- Replace with your actual Firebase/Firestore account creation endpoint
		local url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key="..API_KEY

		-- Prepare the signup data
		local signupData = {
			email = email,
			password = password,
			returnSecureToken = true
		}

		-- Convert to JSON
		local jsonData = HttpService:JSONEncode(signupData)

		-- Make the request
		local response = HttpService:PostAsync(url, jsonData, Enum.HttpContentType.ApplicationJson)

		-- Parse the response
		return HttpService:JSONDecode(response)
	end)

	if success then
		return true, result
	else
		return false, "Failed to create account: " .. tostring(result)
	end
end

function FireStoreManager:Init(uIManager, ui, _plugin)
	UIManager = uIManager
	Ui = ui
	plugin = _plugin
end

function FireStoreManager:PromptLogin()
	assert(UIManager, "FireStoreManager not initialized correctly!")
	warn("Prompting login")
	Ui.Error.Visible = false

	local function ShowError(error)
		Ui.Error.Visible = true
		Ui.Error.Text = error
	end

	UIManager:appendView(Ui)

	UIManager:setLockView(true)

	local connections = {}

	table.insert(connections, Ui.Buttons.Login.MouseButton1Down:Connect(function()
		-- Get email and password from UI inputs
		local email = Ui.Email.Text
		local password = Ui.Password.Text

		-- Validate inputs
		if email == "" or password == "" then
			return ShowError("Email and password cannot be empty")
		end

		-- Disable login button to prevent multiple clicks
		Ui.Buttons.Login.AutoButtonColor = false
		Ui.Buttons.Login.Text = "Logging in..."

		-- Attempt login
		local success, result = tryLogin(password, email)

		-- Reset button
		Ui.Buttons.Login.AutoButtonColor = true
		Ui.Buttons.Login.Text = "Login"

		if success then
			-- Store user data if needed
			FireStoreManager.CurrentUser = result

			-- Close login UI
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			UIManager:removeView(Ui)

			Auth = result
			saveToken(result)
			
			warn(Auth)			
			-- Execute success callback if provided
			if FireStoreManager.OnLoginSuccess then
				FireStoreManager.OnLoginSuccess(result)
			end
		else
			-- Show error message
			ShowError(result)
		end
	end))

	-- Connect signup button
	table.insert(connections, Ui.Buttons.Create.MouseButton1Down:Connect(function()
		-- Get inputs
		local email = Ui.Email.Text
		local password = Ui.Password.Text
		warn(email, password)
		-- Validate inputs
		if email == "" or password == "" then
			return ShowError("Email and password cannot be empty")
		end

		-- Basic email validation
		if not email:match("[^@]+@[^@]+%.%w+") then
			return ShowError("Please enter a valid email address")
		end

		-- Basic password validation
		if #password < 6 then
			return ShowError("Password must be at least 6 characters")
		end

		-- Disable signup button to prevent multiple clicks
		Ui.Buttons.Create.AutoButtonColor = false
		Ui.Buttons.Create.Text = "Creating account..."

		-- Attempt to create account
		local success, result = tryCreateAccount(password, email, "displayName")

		-- Reset button
		Ui.Buttons.Create.AutoButtonColor = true
		Ui.Buttons.Create.Text = "Create Account"

		if success then
			-- Store user data if needed
			FireStoreManager.CurrentUser = result

			-- Close signup UI
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			UIManager:goBack()

			Auth = result
			saveToken(result)

			-- Execute success callback if provided
			if FireStoreManager.OnSignupSuccess then
				FireStoreManager.OnSignupSuccess(result)
			end
		else
			-- Show error message
			ShowError(result)
		end
	end))

end

-- Function to log in from the refresh token
-- @param token: The refresh token to use for authentication
function FireStoreManager:FromRefreshToken(token)
	warn("Refreshing session")
	local success, result = pcall(function()
		local url = "https://securetoken.googleapis.com/v1/token?key=" .. API_KEY

		-- Prepare the refresh token data as URL-encoded string
		local refreshData = "grant_type=refresh_token&refresh_token=" .. HttpService:UrlEncode(token)

		-- Make the request with URL-encoded data
		local response = HttpService:PostAsync(url, refreshData, Enum.HttpContentType.ApplicationUrlEncoded)

		-- Parse the response
		return HttpService:JSONDecode(response)
	end)

	if success then
		
		local result = {
			idToken = result.id_token,
			expiresIn = result.expires_in,
			localId = result.user_id,
			refreshToken = result.refresh_token
		} 
		
		Auth = result
		saveToken(result)
		return true, result
	else
		return false, "Failed to refresh token: " .. tostring(result)
	end
end

--- Function to check if the user is already authenticated
-- @return boolean, string: True if authenticated, false otherwise, and message. The auth data will be stored locally
function FireStoreManager:AuthFromPluginSettings()
	local success, result = pcall(function()
		return plugin:GetSetting("Auth") -- returns : { idToken, expirationTime, localId, refreshToken } as json
	end)

	-- Decode JSON
	if success and result then
		success, result = pcall(function()
			return HttpService:JSONDecode(result)
		end)
	end

	if success and result then
		local expirationTime = result.expirationTime
		local currentTime = os.time()
		if expirationTime and expirationTime > currentTime  then
			-- Token is still valid
			Auth = {
				idToken = result.idToken,
				localId = result.localId,
				refreshToken = result.refreshToken,
				expiresIn = 0,
				kind = ""
			}
			return true, "Authenticated successfully"
		else
			-- Use the refresh token to get a new token
			return FireStoreManager:FromRefreshToken(result.refreshToken)
		end


	else
		return false, "Failed to retrieve authentication data from plugin settings"
	end
end

local function GetValidToken()
	local success, result = FireStoreManager:AuthFromPluginSettings()
	if success then
		return result
	else
		return nil
	end
end

-- Additional helper functions you might want to add
function FireStoreManager:SetLoginCallback(callback)
	self.OnLoginSuccess = callback
end

function FireStoreManager:Logout()
	plugin:SetSetting("Auth", "")
	Auth = nil
end

function FireStoreManager:SetSignupCallback(callback)
	self.OnSignupSuccess = callback
end

function FireStoreManager:IsLoggedIn()
	return  Auth ~= nil
end

function FireStoreManager:GetCurrentUser()
	return Auth
end

--- Function to fetch current user's blocks packages from Firestore
-- @return table: A table containing the user's blocks or nil if an error occurred
function FireStoreManager:GetMyBlocksPackages()
	warn("Fetching user's blocks")
	if not GetValidToken() then
		FireStoreManager:PromptLogin()
		return
	end

	local url = "https://firestore.googleapis.com/v1/projects/" .. PROJECT_ID .. "/databases/(default)/documents:runQuery"

	local queryTable = {
		structuredQuery = {
			from = {
				{
					collectionId = "BlockPackages"
				}
			},
			where = {
				fieldFilter = {
					field = {
						fieldPath = "owner_id"
					},
					op = "EQUAL",
					value = {
						stringValue = Auth.localId
					}
				}
			}
		}
	}

	local queryJson = HttpService:JSONEncode(queryTable)

	local success, responseBody = pcall(function()
		return HttpService:PostAsync(url, queryJson, Enum.HttpContentType.ApplicationJson)
	end)


	if success then
		local data = HttpService:JSONDecode(responseBody)
		return data
	else
		warn("Failed to fetch user's blocks:", responseBody)
		return {}
	end


end

function FireStoreManager:GetTop6BlocksByTag(tag)
	local url = "https://firestore.googleapis.com/v1/projects/" .. PROJECT_ID .. "/databases/(default)/documents:runQuery"
	local queryTable = {
		structuredQuery = {
			from = {
				{
					collectionId = "BlockPackages"
				}
			},
			where = {
				fieldFilter = {
					field = {
						fieldPath = "Tag"
					},
					op = "EQUAL",
					value = {
						stringValue = tag
					}
				}
			}
		}
	}
	

	local queryJson = HttpService:JSONEncode(queryTable)

	local success, responseBody = pcall(function()
		return HttpService:PostAsync(url, queryJson, Enum.HttpContentType.ApplicationJson)
	end)

	if success then
		local data = HttpService:JSONDecode(responseBody)
		return data
	else
		warn("Failed to fetch blocks by tag:", responseBody)
		return {}
	end
end


--- Function to read a document using its path
-- @param path: The path to the document
-- @return table: The document data or nil if an error occurred
function FireStoreManager:ReadDocument(path)


	local url = "https://firestore.googleapis.com/v1/" .. path



	local success, responseBody = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if success then
		local data = HttpService:JSONDecode(responseBody)
		return data
	else
		warn("Failed to read document:", responseBody)
	end
end

--- Function to upload a document to firebase
-- @param document : dictionary to upload
-- @param location : the path 
-- @return boolean: True if the upload was successful, false otherwise and the path to the doc
function FireStoreManager:UploadDocument(documentDic)
	-- Check if we have a valid authentication token
	if not GetValidToken() then
		self:PromptLogin()
		return false
	end

	-- Format URL properly with project ID
	local url = "https://firestore.googleapis.com/v1/projects/" .. PROJECT_ID .. "/databases/(default)/documents/BlockPackages"

	-- Set proper headers
	local headers = {
		["Content-Type"] = "application/json",
		["Authorization"] = "Bearer " .. Auth.idToken
	}

	-- Prepare the document structure according to Firestore API requirements
	local document = {
		fields = {}
	}

	-- Convert each field in the block package to Firestore format
	for fieldName, value in pairs(documentDic) do
		document.fields[fieldName] = self:ConvertToFirestoreValue(value)
	end
	
	document.fields["owner_id"] = self:ConvertToFirestoreValue(Auth.localId)
	-- Encode the document to JSON
	local documentJson = HttpService:JSONEncode(document)

	-- Use RequestAsync for better control
	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = headers,
			Body = documentJson
		})
	end)

	if success and response.Success then
		-- You might want to parse the response to get the created document ID
		local responseData = HttpService:JSONDecode(response.Body)
		print("Block package uploaded successfully with ID:", responseData.name)
		return true, responseData.name
	else
		local errorMessage = success and response.Body or tostring(response)
		warn("Failed to upload block package:", errorMessage)
		return false
	end
end


-- Helper function to convert Firestore value format to Lua values
function FireStoreManager:ConvertFromFirestoreValue(firestoreValue)
	if firestoreValue.stringValue ~= nil then
		return firestoreValue.stringValue
	elseif firestoreValue.integerValue ~= nil then
		return tonumber(firestoreValue.integerValue)
	elseif firestoreValue.doubleValue ~= nil then
		return tonumber(firestoreValue.doubleValue)
	elseif firestoreValue.booleanValue ~= nil then
		return firestoreValue.booleanValue
	elseif firestoreValue.nullValue ~= nil then
		return nil
	elseif firestoreValue.arrayValue ~= nil then
		local result = {}
		if firestoreValue.arrayValue.values then
			for _, v in ipairs(firestoreValue.arrayValue.values) do
				table.insert(result, self:ConvertFromFirestoreValue(v))
			end
		end
		return result
	elseif firestoreValue.mapValue ~= nil then
		local result = {}
		if firestoreValue.mapValue.fields then
			for k, v in pairs(firestoreValue.mapValue.fields) do
				result[k] = self:ConvertFromFirestoreValue(v)
			end
		end
		return result
	end
	
	warn("Unknown Firestore value type:", firestoreValue)
	return nil
end

-- Helper function to convert Lua values to Firestore value format
function FireStoreManager:ConvertToFirestoreValue(value)
	local valueType = type(value)

	if valueType == "string" then
		return { stringValue = value }
	elseif valueType == "number" then
		if math.floor(value) == value then
			return { integerValue = value }
		else
			return { doubleValue = value }
		end
	elseif valueType == "boolean" then
		return { booleanValue = value }
	elseif valueType == "table" then
		if #value > 0 then -- Array-like table
			local arrayValues = {}
			for _, v in ipairs(value) do
				table.insert(arrayValues, self:ConvertToFirestoreValue(v))
			end
			return { arrayValue = { values = arrayValues } }
		else -- Map-like table
			local mapValues = {}
			for k, v in pairs(value) do
				mapValues[k] = self:ConvertToFirestoreValue(v)
			end
			return { mapValue = { fields = mapValues } }
		end
	elseif value == nil then
		return { nullValue = nil }
	end

	warn("Unsupported value type for Firestore:", valueType)
	return { stringValue = tostring(value) }
end

--- Function to modify a document at a given path and fields 
-- @param path: The path to the document
-- @param fields: Dictionary of fields to modify
-- @return boolean: True if the modification was successful, false otherwise
function FireStoreManager:ModifyDocument(path, fields): boolean
	GetValidToken()
	if not Auth then
		self:PromptLogin()
		return false
	end

	--TODO:  ?updateMask.fieldPaths=field1&updateMask.fieldPaths=field2 to modify just the changes
	-- ex: local url = "https://firestore.googleapis.com/v1/" .. docname .. "?updateMask.fieldPaths=fieldName"
	
	local success, result = pcall(function()
		local url = "https://firestore.googleapis.com/v1/"..path

		local packData = {
			fields = {}
		}

		for key, value in pairs(fields) do
			local fireValue = self:ConvertToFirestoreValue(value)
			packData.fields[key] = fireValue
		end
		

		local jsonData = HttpService:JSONEncode(packData)

		local function escapePattern(s)
			return (s:gsub("([^%w])", "%%%1"))
		end
		
		local fix = string.gsub("\"mapValue\":{\"fields\":[ ]}", " ", "")
		jsonData = string.gsub(jsonData, escapePattern(fix), "\"arrayValue\": { \"values\": [ ] }")
		
		local response = HttpService:RequestAsync({
			Url = url,
			Method = "PATCH",
			Headers = {
				["Authorization"] = "Bearer " .. Auth.idToken,
				["Content-Type"] = "application/json"
			},
			Body = jsonData
		})
		
		if not response.Success then
			error(response.StatusCode .. ": " .. response.Body)
		end

		return response
	end)
	
	local responseBody = HttpService:JSONDecode(result.Body or "{}")
	if success and responseBody and responseBody.name then
		return true, responseBody.name
	else
		warn(result)
		return false, "Failed to create block pack: " .. tostring(result)
	end
end

-- Function to post a block to Firestore
function FireStoreManager:PostBlock(block: Block): boolean
	GetValidToken()
	if not Auth then
		self:PromptLogin()
		return false
	end
	
	local success, result = pcall(function()
		local url = "https://firestore.googleapis.com/v1/projects/" .. PROJECT_ID .. "/databases/(default)/documents/Blocks"
		
		
		block.owner_id = Auth.localId

		local packData = {
			fields = {}
		}

		for key, value in pairs((block)) do
			local fireValue = self:ConvertToFirestoreValue(value)
			packData.fields[key] = fireValue
		end
		

		local jsonData = HttpService:JSONEncode(packData)

		local function escapePattern(s)
			return (s:gsub("([^%w])", "%%%1"))
		end
		
		local fix = string.gsub("\"mapValue\":{\"fields\":[ ]}", " ", "")
		jsonData = string.gsub(jsonData, escapePattern(fix), "\"arrayValue\": { \"values\": [ ] }")
		
		local response = HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = {
				["Authorization"] = "Bearer " .. Auth.idToken,
				["Content-Type"] = "application/json"
			},
			Body = jsonData
		})
		
		if not response.Success then
			error(response.StatusCode .. ": " .. response.Body)
		end

		return response
	end)
	
	local responseBody = HttpService:JSONDecode(result.Body or "{}")
	if success and responseBody and responseBody.name then
		return true, responseBody.name
	else
		return false, "Failed to create block pack: " .. tostring(result)
	end
end

-- Function to create a new block package
function FireStoreManager:CreateBlockPack(blockPack: BlockPack)
	GetValidToken()
	if not Auth then
		self:PromptLogin()
		return false
	end
	
	local success, result = pcall(function()
		local url = "https://firestore.googleapis.com/v1/projects/" .. PROJECT_ID .. "/databases/(default)/documents/BlockPackages"
		
		-- Add owner_id to the block pack
		blockPack.owner_id = Auth.localId
		

		local packData = {
			fields = {}
		}

		for key, value in pairs((blockPack)) do
			local fireValue = self:ConvertToFirestoreValue(value)
			packData.fields[key] = fireValue
		end
		

		local jsonData = HttpService:JSONEncode(packData)

		local function escapePattern(s)
			return (s:gsub("([^%w])", "%%%1"))
		end
		
		local fix = string.gsub("\"mapValue\":{\"fields\":[ ]}", " ", "")
		jsonData = string.gsub(jsonData, escapePattern(fix), "\"arrayValue\": { \"values\": [ ] }")
		
		local response = HttpService:RequestAsync({
			Url = url,
			Method = "POST",
			Headers = {
				["Authorization"] = "Bearer " .. Auth.idToken,
				["Content-Type"] = "application/json"
			},
			Body = jsonData
		})
		
		if not response.Success then
			error(response.StatusCode .. ": " .. response.Body)
		end

		return response
	end)

	local responseBody = HttpService:JSONDecode(result.Body or "{}")
	warn(responseBody)
	if success and responseBody and responseBody.name then
		warn(responseBody.name)
		return true, responseBody.name
	else
		warn(result)
		return false, "Failed to create block pack: " .. tostring(result)
	end
end

function FireStoreManager:StarBlockPack(blockPackPath)
	GetValidToken()
	if not Auth then
		self:PromptLogin()
		return false
	end

	local url = "https://firestore.googleapis.com/v1/" .. blockPackPath

	local success, blockData = pcall(function()
		local response = HttpService:GetAsync(url)
		return HttpService:JSONDecode(response)
	end)

	if not success then
		warn("Failed to fetch block pack data:", blockData)
		return false
	end

	local blockPack = blockData.fields


	local downloads = blockPack.Downloads.arrayValue.values
	local userId = Auth.localId
	-- We change just the star field to add/remove the user based on if he is already in there (LocalId)
	local userIndex = nil
	for i, user in ipairs(downloads) do
		if user.stringValue == userId then
			userIndex = i
			break
		end
	end
	if userIndex then
		-- User is already in the list, remove them
		table.remove(downloads, userIndex)
	else
		-- User is not in the list, add them
		table.insert(downloads, { stringValue = userId })
	end

	blockPack.Downloads = { arrayValue = { values = downloads } }

	-- Modify the doc using the specified func

	self:ModifyDocument(blockPackPath, blockPack)


end
function FireStoreManager:RemoveDocument(path)
	GetValidToken()
	if not Auth then
		self:PromptLogin()
		return false
	end

	local url = "https://firestore.googleapis.com/v1/" .. path

	local headers = {
		["Authorization"] = "Bearer " .. Auth.idToken
	}

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "DELETE",
			Headers = headers
		})
	end)

	if success and response.Success then
		return true
	else
		local errorMessage = success and response.Body or tostring(response)
		warn("Failed to delete document:", errorMessage)
		return false
	end
end


return FireStoreManager
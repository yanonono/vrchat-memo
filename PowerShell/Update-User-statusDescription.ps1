# いつも同じユーザーのstatusDescriptionを更新するときは、IDとパスワードを書いて保存すると便利。
$vrcId = ""
$vrcPass = ""

#
#	IDとPassからBasic認証用Base64を作るフォーム
#
function getUserCredential([string] $userId = "", [string] $userPass = "") {
	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing

	$form = New-Object System.Windows.Forms.Form
	$form.Text = 'VRChat Login'
	$form.Size = New-Object System.Drawing.Size(300,300)
	$form.StartPosition = 'CenterScreen'

	$labelId = New-Object System.Windows.Forms.Label
	$labelId.Location = New-Object System.Drawing.Point(10,20)
	$labelId.Size = New-Object System.Drawing.Size(280,20)
	$labelId.Text = 'Username or Email address:'
	$form.Controls.Add($labelId)

	$textBoxId = New-Object System.Windows.Forms.TextBox
	$textBoxId.Location = New-Object System.Drawing.Point(10,40)
	$textBoxId.Size = New-Object System.Drawing.Size(260,20)
	$textBoxId.Text = $userId
	$form.Controls.Add($textBoxId)

	$labelPass = New-Object System.Windows.Forms.Label
	$labelPass.Location = New-Object System.Drawing.Point(10,70)
	$labelPass.Size = New-Object System.Drawing.Size(280,20)
	$labelPass.Text = 'Password:'
	$form.Controls.Add($labelPass)

	$textBoxPass = New-Object System.Windows.Forms.MaskedTextBox
	$textBoxPass.PasswordChar = '*'
	$textBoxPass.Location = New-Object System.Drawing.Point(10, 90)
	$textBoxPass.Size = New-Object System.Drawing.Size(260,20)
	$textBoxPass.Text = $userPass
	$form.Controls.Add($textBoxPass)

	$OKButton = New-Object System.Windows.Forms.Button
	$OKButton.Location = New-Object System.Drawing.Point(75,150)
	$OKButton.Size = New-Object System.Drawing.Size(75,23)
	$OKButton.Text = 'OK'
	$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$form.AcceptButton = $OKButton
	$form.Controls.Add($OKButton)

	$CancelButton = New-Object System.Windows.Forms.Button
	$CancelButton.Location = New-Object System.Drawing.Point(150,150)
	$CancelButton.Size = New-Object System.Drawing.Size(75,23)
	$CancelButton.Text = 'Cancel'
	$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	$form.CancelButton = $CancelButton
	$form.Controls.Add($CancelButton)

	$form.Topmost = $true

	$form.Add_Shown({$textBoxId.Select()})
	$result = $form.ShowDialog()

	if ($result -eq [System.Windows.Forms.DialogResult]::OK)
	{
		return [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $textBoxId.Text, $textBoxPass.Text)))
	}
}

#
#	新しいStatusDescriptionを入力するフォーム
#
function setStatusDescription($statusDescription) {

	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Drawing

	$form = New-Object System.Windows.Forms.Form
	$form.Text = 'VRChat Status Description'
	$form.Size = New-Object System.Drawing.Size(300,200)
	$form.StartPosition = 'CenterScreen'

	$labelStatus = New-Object System.Windows.Forms.Label
	$labelStatus.Location = New-Object System.Drawing.Point(10,20)
	$labelStatus.Size = New-Object System.Drawing.Size(280,20)
	$labelStatus.Text = 'Your Status:'
	$form.Controls.Add($labelStatus)

	$textBoxStatus = New-Object System.Windows.Forms.TextBox
	$textBoxStatus.Location = New-Object System.Drawing.Point(10,40)
	$textBoxStatus.Size = New-Object System.Drawing.Size(260,20)
	$textBoxStatus.Text = $statusDescription
	$form.Controls.Add($textBoxStatus)

	$OKButton = New-Object System.Windows.Forms.Button
	$OKButton.Location = New-Object System.Drawing.Point(75,100)
	$OKButton.Size = New-Object System.Drawing.Size(75,23)
	$OKButton.Text = 'OK'
	$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
	$form.AcceptButton = $OKButton
	$form.Controls.Add($OKButton)

	$CancelButton = New-Object System.Windows.Forms.Button
	$CancelButton.Location = New-Object System.Drawing.Point(150,100)
	$CancelButton.Size = New-Object System.Drawing.Size(75,23)
	$CancelButton.Text = 'Cancel'
	$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
	$form.CancelButton = $CancelButton
	$form.Controls.Add($CancelButton)

	$form.Topmost = $true

	$form.Add_Shown({$textBoxStatus.Select()})
	$result = $form.ShowDialog()

	if ($result -eq [System.Windows.Forms.DialogResult]::OK)
	{
		return $textBoxStatus.Text
	}
}


##################
# VRChat Configを取得
$resVrc = Invoke-WebRequest -Uri "https://api.vrchat.cloud/api/1/config"
$vrcConfig = ConvertFrom-Json $resVrc.Content

# Basic認証用Base64 を設定
$userCred = getUserCredential -userId $vrcId -userPass $vrcPass

# 認証情報(cookie)を取得
$uri = ("https://api.vrchat.cloud/api/1/auth/user?apiKey={0}" -f $vrcConfig.apiKey)
$resUser = Invoke-WebRequest -Uri $uri -Headers @{Authorization=("Basic {0}" -f $userCred)} -SessionVariable vrcSession 
$userinfo = ConvertFrom-Json $resUser.Content

# 新しいstatusDescriptionを設定
$newDescription = setStatusDescription($userinfo.statusDescription)

# 更新処理
$uri = ("https://api.vrchat.cloud/api/1/users/{0}?apiKey={1}" -f $userinfo.id, $vrcConfig.apiKey)

$header = @{
	"Authorization" = ("Basic {0}" -f $userCred);
	"authToken" = $vrcSession.Cookies;
	"Content-Type" = "application/json"
}
$bodyJson = @{statusDescription = $newDescription} | ConvertTo-Json

$resUpdate = Invoke-WebRequest -Method PUT -Uri $uri -Body ([System.Text.Encoding]::UTF8.GetBytes($bodyJson)) -Headers $header
$userUpdatedInfo = ConvertFrom-Json $resUpdate.Content

# 正しく更新されていればメッセージ出力
if($userUpdatedInfo.statusDescription -eq $userinfo.statusDescription){ 
	$wsobj = new-object -comobject wscript.shell
	$result = $wsobj.popup(" UPDATE : VRChat statusDescription.")
}

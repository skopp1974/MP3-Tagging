
[System.Reflection.Assembly]::LoadFile("$PSScriptRoot\taglib-sharp.dll")

function Add-SubProps($object, $prefix) {

	# Add tag subobject properties:
	$props = $object.$prefix | Get-Member -MemberType Property
	$props | ForEach-Object {
		$propname = $_.name
		$writeable = $_.Definition -like '*{get;set;}*'
		$getter = [ScriptBlock]::Create(('$this.{0}.{1}' -f $prefix,$propname))
		if ($writeable) {
			$setter = [ScriptBlock]::Create(('param(${1}) $this.{0}.{1} = ${1}' -f $prefix,$propname))
			try {
				$object = $object | Add-Member -MemberType ScriptProperty -Name $propname -Value $getter -SecondValue $setter -ea Stop -passthru
			} catch {}
		} else {
			try {
				$object = $object | Add-Member -MemberType ScriptProperty -Name $propname -Value $getter -ea Stop -passthru
			} catch {}
		}
	}
	$object
}


function Get-MediaInfo {
	param(
	[Parameter(ValueFromPipelineByPropertyName=$true)]
	[Alias('FullName')]
	$Path
	)

process {
	try {
		$obj = [taglib.File]::Create($Path)
	} catch {}

	if ($obj) {
		$obj = Add-SubProps $obj  'tag'
		Add-SubProps $obj  'properties'
	}

}
}
function Get-PublicMusic {
	$music = [System.Environment]::GetFolderPath('MyMusic')
	$music -replace $env:username, 'Public'
}

function Get-SampleMusic {
	(Get-PublicMusic) + '\Sample Music'
}
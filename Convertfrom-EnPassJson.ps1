function Convertfrom-EnPassJson {
    [CmdletBinding()]
    param (
        [ValidateScript({
            try {
                (Get-Item -path $Path -ErrorAction stop).count -eq 1
            } #try
            catch {
                Throw $_
            } #catch

        })]
        [ValidateNotNullOrWhiteSpace()]
        [String]$Path
    )

    BEGIN {
        Class KeePassStructure {
            [string]$Title
            [string]$Username
            [string]$Password
            [string]$Created
            #! Yes it's a space in the parameter, KeePass expects a space for automatching
            [string]${Last Modified}
            [String]$URL
            [string]$Notes

            KeePassStructure(){}

            KeePassStructure([System.Object]$InputObject) {

                [System.Collections.Hashtable]$ItemHashtable = [System.Collections.Hashtable]::new()
                [System.Collections.Hashtable]$UnkownFields  = [System.Collections.Hashtable]::new()
                [String]$ExtraNotes                          = 'Extra properties from EnPass import:'

                foreach ($Field in $InputObject.fields) {

                    #* if there's already an item with a vlaue, we skip it
                    if (($ItemHashtable[$Field.label])) {
                        continue
                    } #if
                    $ItemHashtable[$Field.label] = $field.value

                    #* If the value is empty, at this point we continue to the next item
                    if ([String]::IsNullOrWhiteSpace($Field.value)) {
                        continue
                    } #if

                    #* Skips handled fields
                    if ($Field.label -in @('Password','Username','Notes','Website','URL')) {
                        continue
                    }  #if

                    $UnkownFields[$Field.label] = $Field.value

                } #foreach

                $This.Title     = $InputObject.title
                $This.Username  = $ItemHashtable['Username']

                #* If username is empty, we attempt to use the Email, as there's no Email field in KeePassXC
                if ([String]::IsNullOrWhiteSpace($This.Username)) {
                    $This.Username = $ItemHashtable['E-mail']
                    $UnkownFields.Remove('E-mail')
                } #if

                #* If  the username and the email field is the same, we remove email
                if ($This.Username -contains $ItemHashtable['E-mail']) {
                    $UnkownFields.Remove('E-mail')
                } #if

                $This.Password        = $ItemHashtable['Password']
                $This.Created         = $InputObject.createdAt
                $This.'Last Modified' = $InputObject.updated_at
                $This.URL             = $ItemHashtable['Website']

                #* Some EnPass entries (In my case) had an URL field
                if ([String]::IsNullOrWhiteSpace($This.URL)) {
                    $This.URL             = $ItemHashtable['URL']
                } #if

                $This.Notes           = $InputObject.note

                #* If there's not any unknown fields at this point we continue to the next entry
                if ($UnkownFields.Keys -eq 0) {
                    continue
                } #if

                #* If there's unknown fields we haven't handled earlier, we add them here to the notes property
                foreach ($Key in $UnkownFields.Keys) {
                    $ExtraNotes += "`n$($Key): $($UnkownFields[$Key])"
                } #if

                if ([String]::IsNullOrWhiteSpace($This.notes)) {
                    $This.notes = $ExtraNotes
                } #if
                else {
                    $This.notes += "`n`n$ExtraNotes"
                } #else

            } #KeePassStructure([System.Object]$InputObject)
        } #Class KeePassStructure
        [System.Collections.Generic.List[KeePassStructure]]$Output = [System.Collections.Generic.List[KeePassStructure]]::new()
        [String]$OutputPath                                        = [System.IO.Path]::ChangeExtension($Path,'csv')

    } #BEGIN

    PROCESS {

        [System.Object]$EnPassItems = ConvertFrom-json -InputObject "$(Get-content -Path $Path -ErrorAction Stop)" -Depth 99 -ErrorAction Stop

        Foreach ($EnPassItem in $EnPassItems.Items) {
            $Output.add(([KeePassStructure]::new($EnPassItem)))
        } #foreach

    } #PROCESS

    END {
        $Output | Export-Csv -Path $OutputPath -Delimiter ';' -ErrorAction Stop
    } #END

} #function Convertfrom-EnPassJson

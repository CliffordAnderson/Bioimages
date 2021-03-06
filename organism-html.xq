xquery version "3.0";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms="http://purl.org/dc/terms/";
declare namespace dwc="http://rs.tdwg.org/dwc/terms/";
declare namespace dwciri="http://rs.tdwg.org/dwc/iri/";
declare namespace dsw="http://purl.org/dsw/";
declare namespace xmp="http://ns.adobe.com/xap/1.0/";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace tc="http://rs.tdwg.org/ontology/voc/TaxonConcept#";
declare namespace txn="http://lod.taxonconcept.org/ontology/txn.owl#";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace blocal="http://bioimages.vanderbilt.edu/rdf/local#";

declare function local:county-units
($state as xs:string, $countryCode as xs:string) as xs:string
{
if ($countryCode = "US" or $countryCode = "CA")
then 
  if ($state = "Louisiana")
  then " Parish"
  else if ($state="Alaska")
        then " Borough"
        else " County"
else
  ""
};

declare function local:substring-after-last
($string as xs:string?, $delim as xs:string) as xs:string?
{
  if (contains($string, $delim))
  then local:substring-after-last(substring-after($string, $delim),$delim)
  else $string
};

declare function local:get-taxon-name-markup
($det as element()+,$name as element()+,$sensu as element()+,$orgID as xs:string)
{
   for $detRecord in $det,
    $nameRecord in $name,
    $sensuRecord in $sensu
  where $detRecord/dsw_identified=$orgID and $nameRecord/dcterms_identifier=$detRecord/tsnID and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
  let $organismScreen := $detRecord/dsw_identified/text()
  group by $organismScreen
  return if ($nameRecord[1]/dwc_taxonRank/text() = "species")
         then (<em>{$nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()}</em>," ("||$nameRecord[1]/dwc_vernacularName/text()||")")
         else 
           if ($nameRecord[1]/dwc_taxonRank/text() = "genus")
           then (<em>{$nameRecord[1]/dwc_genus/text()}</em>," ("||$nameRecord[1]/dwc_vernacularName/text(),")")
           else 
             if ($nameRecord[1]/dwc_taxonRank/text() = "subspecies")
             then (<em>{$nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()}</em>," ssp. ",<em>{$nameRecord/dwc_infraspecificEpithet/text()}</em>, " (", $nameRecord[1]/dwc_vernacularName/text(),")")
             else
               if ($nameRecord[1]/dwc_taxonRank/text() = "variety")
               then (<em>{$nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()}</em>," var. ",<em>{$nameRecord[1]/dwc_infraspecificEpithet/text()}</em>, " (", $nameRecord[1]/dwc_vernacularName/text(),")")
               else ()
};

declare function local:get-taxon-name-clean
($det as element()+,$name as element()+,$sensu as element()+,$orgID as xs:string)
{
   for $detRecord in $det,
    $nameRecord in $name,
    $sensuRecord in $sensu
  where $detRecord/dsw_identified=$orgID and $nameRecord/dcterms_identifier=$detRecord/tsnID and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
  let $organismScreen := $detRecord/dsw_identified/text()
  group by $organismScreen
  return if ($nameRecord[1]/dwc_taxonRank/text() = "species")
         then ($nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()||" ("||$nameRecord[1]/dwc_vernacularName/text()||")")
         else 
           if ($nameRecord[1]/dwc_taxonRank/text() = "genus")
           then ($nameRecord[1]/dwc_genus/text()||" ("||$nameRecord[1]/dwc_vernacularName/text(),")")
           else 
             if ($nameRecord[1]/dwc_taxonRank/text() = "subspecies")
             then ($nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()||" ssp. "||$nameRecord/dwc_infraspecificEpithet/text()||" (", $nameRecord[1]/dwc_vernacularName/text(),")")
             else
               if ($nameRecord[1]/dwc_taxonRank/text() = "variety")
               then ($nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()||" var. "||$nameRecord[1]/dwc_infraspecificEpithet/text()||" (", $nameRecord[1]/dwc_vernacularName/text(),")")
               else ()
};

let $localFilesFolderUnix := "c:/test"

(: Create root folder if it doesn't already exist. :)
let $rootPath := "c:\test"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)

(: Uses http:send-request to fetch CSV files from GitHub :)
(: BaseX 8.0 requires 'map' keyword) before key/value maps :)
(: Older versions of BaseX may not have this requirement :)

(:let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms.csv'/>)[2]:)
let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms-small.csv'/>)[2]
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true() })
(: When we implement Ken's output with pipe ("|") separators, the parse function will have to change to this:
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })
:)

(:let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations.csv'/>)[2]:)
let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations-small.csv'/>)[2]
let $xmlDeterminations := csv:parse($textDeterminations, map { 'header' : true() })

(:let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names.csv'/>)[2]:)
let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names-small.csv'/>)[2]
let $xmlNames := csv:parse($textNames, map { 'header' : true() })

(:let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu.csv'/>)[2]:)
let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu-small.csv'/>)[2]
let $xmlSensu := csv:parse($textSensu, map { 'header' : true() })

(:let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images.csv'/>)[2]:)
let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images-small.csv'/>)[2]
let $xmlImages := csv:parse($textImages, map { 'header' : true() })

(:let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents.csv'/>)[2]:)
let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents-small.csv'/>)[2]
let $xmlAgents := csv:parse($textAgents, map { 'header' : true() })

let $textTourButtons := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/tour-buttons.csv'/>)[2]
let $xmlTourButtons := csv:parse($textTourButtons, map { 'header' : true() })

let $textLinks := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/links.csv'/>)[2]
let $xmlLinks := csv:parse($textLinks, map { 'header' : true() })

let $lastPublishedDoc := fn:doc(concat('file:///',$localFilesFolderUnix,'/last-published.xml'))
let $lastPublished := $lastPublishedDoc/body/dcterms:modified/text()

let $organismsToWriteDoc := file:read-text(concat('file:///',$localFilesFolderUnix,'/organisms-to-write.txt'))
let $xmlOrganismsToWrite := csv:parse($organismsToWriteDoc, map { 'header' : false() })

let $stdViewDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/stdview.xml')
let $viewCategory := $stdViewDoc/view/viewGroup/viewCategory

for $orgRecord in $xmlOrganisms/csv/record, $organismsToWrite in distinct-values($xmlOrganismsToWrite/csv/record/entry)
where $orgRecord/dcterms_identifier/text() = $organismsToWrite
let $taxonNameClean := local:get-taxon-name-clean($xmlDeterminations/csv/record,$xmlNames/csv/record,$xmlSensu/csv/record,$orgRecord/dcterms_identifier/text() )
let $taxonNameMarkup := local:get-taxon-name-markup($xmlDeterminations/csv/record,$xmlNames/csv/record,$xmlSensu/csv/record,$orgRecord/dcterms_identifier/text() )
let $fileName := local:substring-after-last($orgRecord/dcterms_identifier/text(),"/")
let $temp1 := substring-before($orgRecord/dcterms_identifier/text(),concat("/",$fileName))
let $namespace := local:substring-after-last($temp1,"/")
let $filePath := concat($rootPath,"\", $namespace,"\", $fileName,".htm")
let $tempQuoted1 := '"Image of organism" title="Image of organism" src="'
let $tempQuoted2 := '" height="'
let $tempQuoted3 := '"/>'
let $cameoFileName := local:substring-after-last($orgRecord/cameo/text(),"/")
let $temp2 := substring-before($orgRecord/cameo/text(),concat("/",$cameoFileName))
let $cameoNamespace := local:substring-after-last($temp2,"/")
let $googleMapString := "http://maps.google.com/maps?output=classic&amp;q=loc:"||$orgRecord/dwc_decimalLatitude/text()||","||$orgRecord/dwc_decimalLongitude/text()||"&amp;t=h&amp;z=16"
let $qrCodeString := "http://chart.apis.google.com/chart?chs=100x100&amp;cht=qr&amp;chld=|1&amp;chl=http%3A%2F%2Fbioimages.vanderbilt.edu%2F"||$namespace||"%2F"||$fileName||".htm"
let $loadDatabaseString := 'window.location.replace("../metadata.htm?'||$namespace||'/'||$fileName||'/metadata/ind");'
return (file:create-dir(concat($rootPath,"\",$namespace)), file:write($filePath,
<html>{
  <head>
    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
    <meta name="viewport" content="width=320, initial-scale=1" />
    <link rel="icon" type="image/vnd.microsoft.icon" href="../favicon.ico" />
    <link rel="apple-touch-icon" href="../logo.png" />
    <style type="text/css">
    {'@import "../composite-adj.css";'}
    </style>
    <title>An individual of {$taxonNameClean}</title>
    <link rel="meta" type="application/rdf+xml" title="RDF" href="http://bioimages.vanderbilt.edu/kaufmannm/ke129.rdf" />
    <script type="text/javascript">{"
      // Determine if the device is an iPhone, iPad, or a regular browser
      if (navigator.userAgent.indexOf('iPad')!=-1)
       {browser='iPad';}
      else
       {
       if (navigator.userAgent.indexOf('iPhone')!=-1)
         {browser='iPhone';}
       else
         {browser='computer';}
       }
    "}
    </script>
  </head>,
  <body vocab="http://schema.org/" prefix="dcterms: http://purl.org/dc/terms/ foaf: http://xmlns.com/foaf/0.1/">{
    <div resource="{$orgRecord/dcterms_identifier/text()||'.htm'}" typeof="foaf:Document WebPage" >
      <span property="about" resource="{$orgRecord/dcterms_identifier/text()}"></span>
      <span property="dateModified" content="{fn:current-dateTime()}"></span>
    </div>,

    <div id="paste" resource="{$orgRecord/dcterms_identifier/text()}" typeof="dcterms:PhysicalResource">{
      
      if ($xmlTourButtons/csv/record[organism_iri=$orgRecord/dcterms_identifier/text()])
      then (
      <table>{

      for $buttonSet in $xmlTourButtons/csv/record
      where $buttonSet/organism_iri=$orgRecord/dcterms_identifier
      return (
        <tr>{
          if ($buttonSet/previous_iri/text() != "")
          then (
                <td>{
                  <a href="{$buttonSet/previous_iri/text()}">
                    <img alt="previous button" src="{$buttonSet/previous_button_image/text()}" height="58" />
                  </a>
                }</td>
               )
          else (),
          <td>
            <a href="{$buttonSet/home_iri/text()}">
              <img alt="tour home button" src="{$buttonSet/home_button_image/text()}" height="58" />
            </a>
          </td>,
          <td>
            <a href="{$buttonSet/tour_iri/text()}">
              <img alt="tour page button" src="{$buttonSet/tour_button_image/text()}" height="58" />
            </a>
          </td>,
          if ($buttonSet/next_iri/text() != "")
          then (
                <td>{
                  <a href="{$buttonSet/next_iri/text()}">
                    <img alt="next button" src="{$buttonSet/next_button_image/text()}" height="58" />
                  </a>
                }</td>
               )
          else ()
        }</tr>
      )

      }</table>,
      <br/>
        )
      else (),
      
      <span>An individual of {$taxonNameMarkup}</span>,
      <br/>,

      <a href="../{$cameoNamespace}/{$cameoFileName}.htm"><span id="orgimage"><img alt="Image of organism" title="Image of organism" src="../lq/{$cameoNamespace}/w{$cameoFileName}.jpg" /></span></a>,
      <br/>,    

      <h5>Permanent identifier for the individual:</h5>,
      <br/>,
      <h5><strong property="dcterms:identifier">{$orgRecord/dcterms_identifier/text()}</strong></h5>,
      <br/>,
      <br/>,
      
      if ($orgRecord/notes/text() != "")
      then (
            <h3><strong>Notes:</strong></h3>,
            <br/>,
            fn:parse-xml($orgRecord/notes/text()),
            <br/>
           )
      else (),
      
      <table>
        <tr>
          <td><a href="../index.htm"><img alt="home button" src="../logo.jpg" height="88" /></a></td>
          <td><a target="top" href="{$googleMapString}"><img alt="FindMe button" src="../findme-button.jpg" height="88" /></a></td>
          <td><img src="{$qrCodeString}" alt="QR Code" /></td>
        </tr>
      </table>,
      <br/>,
(: It doesn't seem to be a problem that the quotes in the onclick value get escaped :)
      <h5><a href="#" onclick='{$loadDatabaseString}'>&#8239;Load database and switch to thumbnail view</a>
      </h5>,
      <br/>,
      <br/>,
      <h5>
        <em>Use this URL as a stable link to this page:</em>
        <br/>
        <a href="{$fileName||'.htm'}">http://bioimages.vanderbilt.edu/{$namespace}/{$fileName}.htm</a>
      </h5>,
      <br/>,
      <br/>,
      if ($orgRecord/dwc_collectionCode/text() != "")
      then (
           for $agent in $xmlAgents/csv/record
           where $agent/dcterms_identifier=$orgRecord/dwc_collectionCode
           return (<h5>This individual is a living specimen that is part of the&#8239;
           <a href="{$agent/contactURL/text()}">{$agent/dc_contributor/text()}</a>
           &#8239;with the local identifier {$orgRecord/dwc_catalogNumber/text()}.</h5>,<br/>,
              <br/>)
           )
      else (),

      <h5><em>This particular individual is believed to be </em><strong>{$orgRecord/dwc_establishmentMeans/text()}</strong>.</h5>,
      <br/>,

      if ($orgRecord/dwc_organismName/text() != "")
      then (
            <h5><em>It has the name </em>&quot;<strong>{$orgRecord/dwc_organismName/text()}</strong>&quot;.</h5>,<br/>
           )
      else (),

      if ($orgRecord/dwc_organismScope/text() != "multicellular organism")
      then (
            <h5><em>This entity has the scope: </em><strong>{$orgRecord/dwc_organismScope/text()}</strong>.</h5>,<br/>
           )
      else (),

      if ($orgRecord/dwc_organismRemarks/text() != "")
      then (
            <h5><em>Remarks:</em><strong>{$orgRecord/dwc_organismRemarks/text()}</strong></h5>,<br/>
           )
      else (),

      <br/>,
      <h3><strong>Identifications:</strong></h3>,
      <br/>,
      for $detRecord in $xmlDeterminations/csv/record,
          $nameRecord in $xmlNames/csv/record,
          $sensuRecord in $xmlSensu/csv/record
      where $detRecord/dsw_identified=$orgRecord/dcterms_identifier and $nameRecord/dcterms_identifier=$detRecord/tsnID and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
      order by $detRecord/dwc_dateIdentified/text() descending
      return (
      <h2>{
      if ($nameRecord/dwc_taxonRank/text() = "species")
             then (<em>{$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()}</em>," ("||$nameRecord/dwc_vernacularName/text()||")")
             else 
               if ($nameRecord/dwc_taxonRank/text() = "genus")
               then (<em>{$nameRecord/dwc_genus/text()}</em>," ("||$nameRecord/dwc_vernacularName/text(),")")
               else 
                 if ($nameRecord/dwc_taxonRank/text() = "subspecies")
                 then (<em>{$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()}</em>," ssp. ",<em>{$nameRecord/dwc_infraspecificEpithet/text()}</em>, " (", $nameRecord/dwc_vernacularName/text(),")")
                 else
                   if ($nameRecord/dwc_taxonRank/text() = "variety")
                   then (<em>{$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()}</em>," var. ",<em>{$nameRecord/dwc_infraspecificEpithet/text()}</em>, " (", $nameRecord/dwc_vernacularName/text(),")")
                   else ()
        }</h2>,
        <span> </span>,
        <h3>{$nameRecord/dwc_scientificNameAuthorship/text()}</h3>,
        <h6>sec. {$sensuRecord/tcsSignature/text()}</h6>,
        <br/>,
        <span>common name: {$nameRecord/dwc_vernacularName/text()}</span>,
        <br/>,
        <span>family: {$nameRecord/dwc_family/text()}</span>,
        <br/>,
        <h6>{
          <em>Identified </em>,
          <span>{$detRecord/dwc_dateIdentified/text()}</span>,
          <em> by </em>,
          for $agentRecord in $xmlAgents/csv/record
          where $agentRecord/dcterms_identifier=$detRecord/identifiedBy
          return <a href="{$agentRecord/contactURL/text()}">{$agentRecord/dc_contributor/text()}</a>
        }</h6>,
        <br/>,
        <br/>
      ),
      
      <h3><strong>Location:</strong></h3>,
      <br/>,
      
      for $depiction in $xmlImages/csv/record
      where $depiction/foaf_depicts=$orgRecord/dcterms_identifier
      let $organismID := $orgRecord/dcterms_identifier
      group by $organismID
      return (            
        <span>{$depiction[1]/dwc_locality/text()}, {$depiction[1]/dwc_county/text()}{local:county-units($depiction[1]/dwc_stateProvince/text(), $depiction[1]/dwc_countryCode/text() )}, {$depiction[1]/dwc_stateProvince/text()}, {$depiction[1]/dwc_countryCode/text()}</span>,
        <br/>,
        <span>Click on these geocoordinates to load a map showing the location: </span>,
        <a target="top" href="http://maps.google.com/maps?output=classic&amp;q=loc:{$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;t=h&amp;z=16">{$orgRecord/dwc_decimalLatitude/text()}&#176;, {$orgRecord/dwc_decimalLongitude/text()}&#176;</a>,
        <br/>,
        <h6>Coordinate uncertainty about:  {$depiction[1]/dwc_coordinateUncertaintyInMeters/text()}  m.  </h6>,
        if ($orgRecord/geo_alt/text() != "-9999")
        then (
              <h6>Altitude: {$orgRecord/geo_alt/text()}.  </h6>
             )
        else (),
        <br/>,
        <h6>{$orgRecord/dwc_georeferenceRemarks/text()}</h6>,
        <br/>,        
        <img src="http://maps.googleapis.com/maps/api/staticmap?center={$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;zoom=14&amp;size=300x300&amp;markers=color:green%7C{$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;sensor=false"/>,
        <img src="http://maps.googleapis.com/maps/api/staticmap?center={$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;maptype=hybrid&amp;zoom=18&amp;size=300x300&amp;markers=color:green%7C{$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;sensor=false"/>,
        <br/>,
        <br/>
      ),
      
      <strong>Occurrences were recorded for this individual on the following dates:</strong>,
      <br/>,
      for $depiction in $xmlImages/csv/record
      where $depiction/foaf_depicts=$orgRecord/dcterms_identifier
      let $occurrenceDate := substring($depiction/dcterms_created/text(),1,10)
      group by $occurrenceDate
      return (
        <a id="{$occurrenceDate}">{$occurrenceDate}</a>,
        <br/>
        ),
        <br/>,
        
      <strong>The following images document this individual.</strong>,
      <br/>,
      <span> Click on the link to view the image and its metadata.</span>,
      <a href="#" onclick='window.location.replace("../metadata.htm?{$namespace}/{$fileName}/metadata/ind");'>View sorted thumbnails and enable site navigation.</a>,
      <br/>,
      <br/>,
      <table border="1" cellspacing="0">{
        <tr><td>Image identifier</td><td>View</td></tr>,
        for $depiction in $xmlImages/csv/record, $viewCat in $viewCategory
        where $depiction/foaf_depicts=$orgRecord/dcterms_identifier and $viewCat/stdview/@id = substring($depiction/view/text(),2)
        order by substring($depiction/view/text(),2)
        return (
                <tr>{
                  <td>{
                    <a href="{$depiction/dcterms_identifier/text()}.htm">{$depiction/dcterms_identifier/text()}</a>
                  }</td>,
                  <td>{data($viewCat/@name)||" - "||data($viewCat/stdview[@id=substring($depiction/view/text(),2)]/@name)}</td>
                }</tr>
               )
      }</table>,
      <br/>,

      for $detRecord in $xmlDeterminations/csv/record, $sensuRecord in $xmlSensu/csv/record
      where $detRecord/dsw_identified=$orgRecord/dcterms_identifier and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
      let $sensuScreen := $sensuRecord/dcterms_identifier/text()
      group by $sensuScreen
      return (
      <h6>{$sensuRecord/tcsSignature/text()} =</h6>,
      <br/>,
      <h6>{$sensuRecord/dc_creator/text()}, {$sensuRecord/dcterms_created/text()}. {$sensuRecord/dcterms_title/text()}. {$sensuRecord/dc_publisher/text()}. </h6>,
      <br/>
          ),
      <br/>,
      <h5>{
        <em>Metadata last modified: </em>,
        <span>{fn:current-dateTime()}</span>,
        <br/>,
        <a target="top" href="{$orgRecord/dcterms_identifier/text()||'.rdf'}">RDF formatted metadata for this individual</a>,
        <br/>
      }</h5>
    }</div>,
    <script type="text/javascript">{'
    document.getElementById("paste").setAttribute("class", browser); // set css for browser type
    '}</script>,
    <script type="text/javascript">{"
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
    
      ga('create', 'UA-45642729-1', 'vanderbilt.edu');
      ga('send', 'pageview');
    "}</script>
  }</body>
}</html>
       )),
let $localFilesFolderPC := "c:\test"
let $lastPublished := fn:current-dateTime()
return (file:write(concat($localFilesFolderPC,"\last-published.xml"),
<body>
<dcterms:modified>{$lastPublished}</dcterms:modified>
</body>
))

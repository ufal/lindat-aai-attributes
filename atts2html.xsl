<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:atts="http://lindat.cz/attributes">

	<xsl:template match="/">
		<html>
			<head>
				<script src="//code.jquery.com/jquery-1.11.1.min.js" />			
				<link rel="stylesheet" href="/common-theme-b3/public/bootstrap/css/bootstrap.min.css" />
				<link rel="stylesheet" href="/common-theme-b3/public/bootstrap/js/bootstrap.min.js" />
				<link rel="stylesheet" type="text/css" href="/common-theme-b3/public/css/lindat.css" />
                <script src="../static/bootstrap-3.0.3/bootstrap.min.js" />
                <script src="./aai-stats.js" />
			</head>

			<body>
                <xsl:copy-of select="document('../static/qa/header.htm')"/>
				<div class="container">
					<xsl:call-template name="idp_list" />
					<!-- xsl:apply-templates select="//atts:idp" /-->
					<xsl:call-template name="interesting_attributes" />
					<xsl:call-template name="info_skipped" />
					<xsl:call-template name="info_removed" />
					<xsl:call-template name="attribute_map" />
					<xsl:call-template name="entity_search" />
				</div>
                <xsl:copy-of select="document('/common-theme-b3/footer.htm')"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="atts:idp">
		<div class="panel panel-default">
		   <xsl:attribute name="id"><xsl:value-of select="position()" /></xsl:attribute>		
		  <div class="panel-heading">
		    <h3 class="panel-title"><xsl:value-of select="./@entityId" /></h3>
		  </div>
		  <div class="panel-body">
		    <xsl:apply-templates select="./*/atts:list" />
		  </div>
		</div>		
	</xsl:template>

	<xsl:template match="atts:list">
		<table class="table table-condensed">
			<tbody>
			<tr class="success">
				<td colspan="4">
					<xsl:value-of select="./atts:firstSeen" />
					-
					<xsl:value-of select="./atts:lastSeen" />
				</td>
			</tr>
			<tr>
				<td><strong>No.</strong></td>
				<td><strong>Name</strong></td>
				<td><strong>Friendly Name</strong></td>
				<td><strong>Name Format</strong></td>
			</tr>
			<xsl:for-each select="./atts:attr">
				<xsl:apply-templates select=".">
					<xsl:with-param name="num" select="position()" />
				</xsl:apply-templates>
			</xsl:for-each>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template match="atts:attr">
		<xsl:param name="num" />
		<tr>
			<td>
				<xsl:value-of select="$num" />
			</td>
			<td>
				<xsl:choose>
					<xsl:when
						test="starts-with(./atts:Name, 'urn:oid:1.3.6.1.4.1.5923.1.1')">
						<xsl:element name="a">
							<xsl:attribute name="href">http://www.internet2.edu/products-services/trust-identity-middleware/mace-registries/internet2-object-identifier-oid-registrations</xsl:attribute>
							<xsl:value-of select="./atts:Name" />
						</xsl:element>
					</xsl:when>
					<xsl:when test="starts-with(./atts:Name, 'urn:oid')">
						<xsl:element name="a">
							<xsl:attribute name="href">http://oid-info.com/get/<xsl:value-of
								select="./atts:Name" /></xsl:attribute>
							<xsl:value-of select="./atts:Name" />
						</xsl:element>
					</xsl:when>
					<xsl:when test="starts-with(./atts:Name, 'http://')">
						<xsl:element name="a">
							<xsl:attribute name="href"><xsl:value-of
								select="./atts:Name" /></xsl:attribute>
							<xsl:value-of select="./atts:Name" />
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="./atts:Name" />
					</xsl:otherwise>
				</xsl:choose>
			</td>
			<td>
				<xsl:value-of select="./atts:FriendlyName" />
			</td>
			<td>
				<xsl:value-of select="./atts:NameFormat" />
			</td>
		</tr>
	</xsl:template>

	<xsl:template name="idp_list">
		<div class="alert alert-warning">
			The following is a list of Attribute(s) as sent by IDPs in
			AttributeStatement. The values "Name", "FriendlyName" and
			"NameFormat" are obtained from the received XML element only. The
			"Name" might be turned into a link to a definition of that attribute
			(not guaranteed to work). At the
			<a href="#interesting_attributes">end of the page</a>
			there is a summary for some chosen attributes.
		</div>
		<h2>IDPs</h2> <span class="pull-right">(updated <xsl:value-of select="//atts:lastAccess"/>)</span>
		<span class="label label-default" style="margin: 5px">Total = <xsl:value-of select="count(//atts:idp)" /></span>
		<span class="label label-info" style="margin: 5px">ClarinSPF = <xsl:value-of select="count(//atts:idp[@clarinSPF='true'])" /></span>
		<span class="label label-primary" style="margin: 5px">eduGAIN = <xsl:value-of select="count(//atts:idp[@eduGain='true'])" /></span>
		<span class="label label-success" style="margin: 5px">eduID.cz = <xsl:value-of select="count(//atts:idp[@eduID='true'])" /></span>		
		
		<span class="label label-default" style="margin: 5px">IN ALL = <xsl:value-of select="count(//atts:idp[@eduGain='true' and @clarinSPF='true' and @eduID='true'])" /></span>
		<span class="label label-default" style="margin: 5px">only in eduGAIN = <xsl:value-of select="count(//atts:idp[@eduGain='true' and not(@clarinSPF) and not(@eduID)])" /></span>
		<span class="label label-default" style="margin: 5px">only in SPF = <xsl:value-of select="count(//atts:idp[not(@eduGain) and @clarinSPF='true' and not(@eduID)])" /></span>
		<span class="label label-default" style="margin: 5px">only in eduID.cz = <xsl:value-of select="count(//atts:idp[not(@eduGain) and not(@clarinSPF) and @eduID='true'])" /></span>
		


		
		<div class="panel-group" id="accordion" style="margin-top: 20px;">
		<xsl:for-each select="//atts:idp">
		  <div class="panel panel-default">
		    <div class="panel-heading">
		      <h4 class="panel-title">
		        <a data-toggle="collapse" data-parent="#accordion">
						<xsl:attribute name="href">#<xsl:value-of select="position()" /></xsl:attribute>
						<xsl:value-of select="./@entityId" />							          
		        </a>
					<xsl:if test="./@clarinSPF='true'">
						<span class="label label-info pull-right" style="margin-left: 10px;">ClarinSPF</span>
					</xsl:if>
					<xsl:if test="./@eduGain='true'">
						<span class="label label-primary pull-right" style="margin-left: 10px;">eduGAIN</span>
					</xsl:if>
					<xsl:if test="./@eduID='true'">
						<span class="label label-success pull-right" style="margin-left: 10px;">eduID.cz</span>
					</xsl:if>								        													        
		      </h4>
		    </div>
		    <div class="panel-collapse collapse">
		      <xsl:attribute name="id"><xsl:value-of select="position()" /></xsl:attribute>
		      <div class="panel-body">
						<xsl:apply-templates />
		      </div>
		    </div>
		  </div>
		  </xsl:for-each>
		</div>				
	</xsl:template>

	<xsl:template name="interesting_attributes">
		<div style="margin-top: 20px">
		<hr />
		<h2 id="interesting_attributes">Interesting attributes</h2>
		<div class="alert alert-warning">The attribute is counted as present if it is in the last received set of
			attributes. The number in the totals row is sum of all the rows
			below. We check for the following attributes:
			<ul>
				<li>eppn</li>
				<ul>
					<li>urn:mace:dir:attribute-def:eduPersonPrincipalName</li>
					<li>urn:oid:1.3.6.1.4.1.5923.1.1.1.6</li>
				</ul>

				<li>persistent-id (targeted id)</li>
				<ul>
					<li>urn:mace:dir:attribute-def:eduPersonTargetedID</li>
                    <li>urn:oid:1.3.6.1.4.1.5923.1.1.1.10</li>
                    <li>urn:oasis:names:tc:SAML:2.0:nameid-format:persistent</li>
				</ul>
				<li>email</li>
				<ul>
					<li>urn:oid:0.9.2342.19200300.100.1.3</li>
					<li>urn:oid:1.2.840.113549.1.9.1</li>
					<li>urn:mace:dir:attribute-def:mail</li>
					<li>mail</li>
				</ul>
				<li>affiliation*</li>
				<ul>
                  <li>urn:oid:1.3.6.1.4.1.5923.1.1.1.1</li>
                  <li>urn:oid:1.3.6.1.4.1.5923.1.1.1.9</li>
                  <li>urn:oid:1.3.6.1.4.1.5923.1.1.1.5</li>
                  <li>urn:mace:dir:attribute-def:eduPersonScopedAffiliation</li>
                  <li>urn:mace:dir:attribute-def:eduPersonAffiliation</li>
                  <li>urn:mace:dir:attribute-def:eduPersonPrimaryAffiliation</li>
				</ul>

			</ul>
		</div>
		<table class="table table-condensed">
			<tr>
				<tr>
					<td></td>
					<td><strong>only eppn</strong></td>
					<td><strong>only persistent-id</strong></td>
					<td><strong>eppn</strong></td>
					<td><strong>persistent-id</strong></td>
					<td><strong>email</strong></td>
					<td><strong>affiliation*</strong></td>
				</tr>
                         <td>Totals</td>
                         <td id="only-total-eppn"></td>
                         <td id="only-total-persistent"></td>
                         <td><xsl:value-of select="count(//atts:idp/atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
text()='urn:mace:dir:attribute-def:eduPersonPrincipalName' 
or 
text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.6'
]])"/></td>
                         <td><xsl:value-of select="count(//atts:idp/atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
text()='urn:mace:dir:attribute-def:eduPersonTargetedID' 
or 
text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.10'
or
text()='urn:oasis:names:tc:SAML:2.0:nameid-format:persistent'
]])"/></td>
                         <td><xsl:value-of select="count(//atts:idp/atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
text()='urn:oid:0.9.2342.19200300.100.1.3' 
or 
text()='urn:oid:1.2.840.113549.1.9.1' 
or 
text()='urn:mace:dir:attribute-def:mail'
or 
text()='mail'
]])"/></td>
                         <td><xsl:value-of select="count(//atts:idp/atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.1' 
or
text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.9' 
or
text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.5' 
or
text()='urn:mace:dir:attribute-def:eduPersonScopedAffiliation'
or
text()='urn:mace:dir:attribute-def:eduPersonAffiliation'
or
text()='urn:mace:dir:attribute-def:eduPersonPrimaryAffiliation'
]])"/></td>

                 </tr>
                 <xsl:for-each select="//atts:idp">
                         <tr>
                                 <td><xsl:value-of select="./@entityId"/></td>
                                 <td class="only-one-eppn mark-num">
                                         <xsl:choose>
                                         <xsl:when test="./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
    text()='urn:mace:dir:attribute-def:eduPersonPrincipalName' 
    or 
    text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.6'
]] and ./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
    text()='urn:mace:dir:attribute-def:eduPersonTargetedID' 
    or 
    text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.10'
]]"/>
                                         <xsl:when test="./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
    text()='urn:mace:dir:attribute-def:eduPersonTargetedID' 
    or 
    text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.10'
]]"/>

                                         <xsl:when test="./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
    text()='urn:mace:dir:attribute-def:eduPersonPrincipalName' 
    or 
    text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.6'
]]">
    1
                                         </xsl:when>
                                         <xsl:otherwise>
                                         	<xsl:attribute name="class"></xsl:attribute>
                                         	<small class='alert-danger'>both missing</small>
                                         </xsl:otherwise>
                                         </xsl:choose>
                                 </td>

                                 <td class="only-one-persistent mark-num">
                                         <xsl:choose>
                                         <xsl:when test="./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
    text()='urn:mace:dir:attribute-def:eduPersonPrincipalName' 
    or 
    text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.6'
]] and ./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
    text()='urn:mace:dir:attribute-def:eduPersonTargetedID' 
    or 
    text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.10'
]]"/>
                                         <xsl:when test="./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
    text()='urn:mace:dir:attribute-def:eduPersonPrincipalName' 
    or 
    text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.6'
]]"/>

                                         <xsl:when test="./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
    text()='urn:mace:dir:attribute-def:eduPersonTargetedID' 
    or 
    text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.10'
]]">
    1
                                         </xsl:when>
                                         <xsl:otherwise>
                                         	<xsl:attribute name="class"></xsl:attribute>
                                         	<small class='alert-danger'>both missing</small>
                                         </xsl:otherwise>
                                         </xsl:choose>
                                 </td>

                                 <td class="mark-num"><xsl:value-of select="count(./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
text()='urn:mace:dir:attribute-def:eduPersonPrincipalName' 
or
 text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.6'
]])"/></td>
                                 <td class="mark-num"><xsl:value-of select="count(./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
text()='urn:mace:dir:attribute-def:eduPersonTargetedID' 
or 
text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.10'
]])"/></td>
                         		<td class="mark-num"><xsl:value-of select="count(./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
text()='urn:oid:0.9.2342.19200300.100.1.3' 
or 
text()='urn:oid:1.2.840.113549.1.9.1'
or 
text()='urn:mace:dir:attribute-def:mail'
]])"/></td>
                         		<td class=""><xsl:value-of select="count(./atts:seenAttrLists/atts:list[last()][atts:attr/atts:Name[
text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.1' 
or
text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.9' 
or
text()='urn:oid:1.3.6.1.4.1.5923.1.1.1.5' 
or
text()='urn:mace:dir:attribute-def:eduPersonScopedAffiliation'
or
text()='urn:mace:dir:attribute-def:eduPersonAffiliation'
or
text()='urn:mace:dir:attribute-def:eduPersonPrimaryAffiliation'

]])"/></td>

                         </tr>
                 </xsl:for-each>
		</table>
		</div>
	</xsl:template>

	<xsl:template name="info_skipped">
		<div style="margin-top: 20px">
		<hr />
		<h2 id="info_skipped">Skipped attributes from shibd.log</h2>

       <div class="panel-group" id="accordion" role="tablist" aria-multiselectable="true">
        <div class="panel panel-default">
          <div class="panel-heading" role="tab" id="headingOne">
            <h2 class="panel-title">
                <a data-toggle="collapse" data-parent="#accordion" href="#collapse-skipped" aria-expanded="false" aria-controls="collapseOne">
                    <i class="fa fa-caret-square-o-down fa-2x"></i></a>
            </h2>
          </div>
          <div id="collapse-skipped" class="panel-collapse collapse" role="tabpanel" aria-labelledby="headingOne">
            <div class="panel-body">
                <ol class="table table-condensed table-striped ">
            		<xsl:for-each select="//atts:info-skipped/atts:value">
                    <li>
        	            <strong><xsl:value-of select="./text()" /></strong>
            		</li>
        			</xsl:for-each>
        		</ol>
              </div>
          </div>
        </div>
       </div>

        </div>
	</xsl:template>

	<xsl:template name="info_removed">
		<div style="margin-top: 20px">
		<hr />
		<h2 id="info_skipped">Removed attributes from shibd.log</h2>

       <div class="panel-group" id="accordion" role="tablist" aria-multiselectable="true">
        <div class="panel panel-default">
          <div class="panel-heading" role="tab" id="headingOne">
            <h2 class="panel-title">
                <a data-toggle="collapse" data-parent="#accordion" href="#collapse-removed" aria-expanded="false" aria-controls="collapseOne">
                    <i class="fa fa-caret-square-o-down fa-2x"></i></a>
            </h2>
          </div>
          <div id="collapse-removed" class="panel-collapse collapse" role="tabpanel" aria-labelledby="headingOne">
            <div class="panel-body">
                <ol class="table table-condensed table-striped ">
            		<xsl:for-each select="//atts:info-removed/atts:value">
                        <li>
            	            <strong><xsl:value-of select="./text()" /></strong>
                		</li>
        			</xsl:for-each>
        		</ol>
              </div>
          </div>
        </div>
       </div>
        </div>
	</xsl:template>

	<xsl:template name="attribute_map">
		<div style="margin-top: 20px; margin-bottom:40px">
		<hr />
		<h2 id="info_skipped">attribute-map.xml</h2>
       <div class="panel-group" id="accordion" role="tablist" aria-multiselectable="true">
        <div class="panel panel-default">
          <div class="panel-heading" role="tab" id="headingOne">
            <h2 class="panel-title">
                <a data-toggle="collapse" data-parent="#accordion" href="#collapseOne" aria-expanded="false" aria-controls="collapseOne">
                    <i class="fa fa-caret-square-o-down fa-2x"></i></a>
            </h2>
          </div>
          <div id="collapseOne" class="panel-collapse collapse" role="tabpanel" aria-labelledby="headingOne">
            <div class="panel-body">
                 <pre>
        		     <xsl:value-of select="//atts:attribute-map" />
                 </pre>
              </div>
          </div>
        </div>
       </div>
        </div>
	</xsl:template>

	<xsl:template name="entity_search">
		<div style="margin-top: 20px; margin-bottom:40px">
		<hr />
		<h2 id="entity_search">Entity search</h2>

            <div class="form-inline">
                <button type="submit" id="idp-load-idps" class="btn btn-primary">Load IdPs</button>
                <div class="input-group">
                    <input type="text" id="idp-input-url" class="form-control" placeholder="discofeed url"  style="min-width: 400px;" />
                    <div class="input-group-addon">IdPs count: <span class="label label-warning" id="ids-count">0</span></div>
                </div>
                <div class="input-group">
                    <div class="input-group-addon">Search in</div>
                    <select id="idp-search-in">
                        <option value="entityID">entityID</option>
                        <option value="DisplayNames">DisplayNames</option>
                        <option value="Descriptions">Descriptions</option>
                    </select>
                </div>
            </div>
            <div class="form-inline idp-filter">
                    <div class="input-group">
                        <div class="input-group-addon">AND</div>
                        <input type="text" class="idp-regexp form-control" value=".*" />
                    </div>
                    <div class="checkbox">
                        <label><input class="checkbox-inverse" type="checkbox" />Inverse</label>
                        <label><input class="checkbox-ignorecase" type="checkbox" />Ignore case</label>
                    </div>
            </div>

            <div class="form-inline">
                    <button type="submit" id="idp-search" class="btn btn-primary">Search</button>
                    <button type="submit" id="idp-add-filter" class="btn btn-primary">Add filter</button>
                    <button type="submit" id="idp-clear" class="btn btn-primary">Clear</button>
                    <button type="submit" id="idp-list" class="btn btn-primary">List</button>
            </div>

    <div id="idp-result" class="row col-sm-offset-2 col-sm-8" style="min-height: 100px" >
    </div>

    </div>

	</xsl:template>


</xsl:stylesheet>



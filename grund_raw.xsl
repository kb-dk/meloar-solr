<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                version="1.0" exclude-result-prefixes="xs xsl">
  <xsl:output version="1.0" encoding="UTF-8" indent="yes" method="text" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  
  <!-- Very primitive TEI-support: Extracts a few selected elements and pipes all text -->

  <xsl:template match="//tei:text/tei:body//text()">
    <xsl:variable name="next" select="local-name(following-sibling::node()[1])" />
    <xsl:value-of select="translate(concat(.,'&#xA;'),'&#x0d;&#x0a;', '')"/>
    
    <xsl:choose>
      <xsl:when test="$next = 'hi' or $next = 'pb' ">
        <xsl:text> </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>
</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="text()"/> <!-- Garbage clean up -->
  <xsl:template match="//tei:fw//text()"/>


</xsl:stylesheet>

  

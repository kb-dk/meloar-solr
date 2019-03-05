<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:tei="http://www.tei-c.org/ns/1.0"
                version="1.0" exclude-result-prefixes="xs xsl">
  <xsl:output version="1.0" encoding="UTF-8" indent="yes" method="xml" omit-xml-declaration="no"/>
  <xsl:strip-space elements="*"/>
  
  <!-- Very primitive TEI-support: Extracts a few selected elements and pipes all text -->

  <xsl:template match="/">
    <add><doc>
      <xsl:for-each select="tei:TEI/*">
        <xsl:apply-templates/>
      </xsl:for-each>
    </doc></add>
  </xsl:template>

  <xsl:template match="tei:text/tei:body//text()">
    <field name="content">
      <xsl:variable name="next" select="local-name(following-sibling::node()[1])" />
      <xsl:value-of select="translate(concat(.,'&#xA;'),'&#x0d;&#x0a;', '')"/>
    
      <xsl:choose>
        <xsl:when test="$next = 'hi' or $next = 'seg' or $next = 're' or $next = 'persName'">
          <xsl:text> </xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>
</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </field>
          <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="tei:text/tei:body//tei:p">
    <field name="content">
      <xsl:for-each select="*//text()">
        <xsl:value-of select="translate(concat(.,'&#xA;'),'&#x0d;&#x0a;', '')"/>
          <xsl:text> </xsl:text>
      </xsl:for-each>
    </field>
          <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="tei:teiHeader//tei:titleStmt/tei:title">
    <xsl:if test="not(@type='sub') and not(@rend='shortForm') and not(@rend='partForm')">
    <field name="title">
      <xsl:value-of select="."/>
    </field><xsl:text>
</xsl:text>
    </xsl:if>
  </xsl:template>

  <xsl:template match="tei:teiHeader//tei:titleStmt/tei:author">
    <field name="author">
      <xsl:value-of select="."/>
    </field><xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="tei:teiHeader//tei:publicationStmt/tei:date">
    <field name="ctime">
      <xsl:choose>
        <xsl:when test="string-length(@when) = 4">
          <xsl:value-of select="@when"/><xsl:text>-01-01T00:00:00Z</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@when"/><xsl:text>T00:00:00Z</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </field><xsl:text>
</xsl:text>
    <field name="year">
      <xsl:value-of select="substring(@when, 1, 4)"/>
      </field><xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="text()"/> <!-- Garbage clean up -->

</xsl:stylesheet>

  

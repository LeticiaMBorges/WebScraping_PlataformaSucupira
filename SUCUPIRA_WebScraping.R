
# Web Scraping com a plataforma SUCUPIRA                       


## Pacotes necess�rios:

library(RSelenium)
library(xml2)
library(rvest)
library(stringr)
library(dplyr)

## Fun��o que calcula o n�mero de programas dispon�veis para a �rea de avalia��o
## fornecida, bem como o n�mero de p�ginas:
calculate.pages <- function() {
  
  ## Conta o n�mero de programas :
  count.programs <- rd$getPageSource() %>% 
    unlist() %>%
    read_html() %>%
    html_node(xpath = '//*[@id="form:j_idt87:div_paginacao"]') %>%
    html_text(trim = TRUE) %>%
    str_match_all("[0-9]+") %>%
    unlist() %>%
    .[3] %>%
    as.numeric()
  
  ## Conta o n�mero de p�ginas em que estes programas est�o dispostos :
  count.pages <- 1 + count.programs %/% 50
  
  ## Retorna as informa��es :
  list("N_Programas" = count.programs, "N_paginas" = count.pages) %>% return()
  
}

## Fun��o respons�vel por extrair os links contidas nos seletores xpath :
extract.links <- function(xpath.vector) {
  
  links.vector <- rep(0, times = length(xpath.vector))
  
  ## Interage com o  vetor de xpaths com o objetivo de extrair os links :
  for (i in 1:length(xpath.vector)) {
    
    links.vector[i] <-  rd$getPageSource() %>% 
      unlist() %>%
      read_html() %>%
      html_nodes(xpath = xpath.vector[i]) %>%
      as.character() %>%
      str_extract('(?<=href=\\")(.*?)(?=" )')
    
    links.vector[i] <- str_c("https://sucupira.capes.gov.br", links.vector[i])
    
  }
  
  ## Retorna o vetor resposta :
  return(links.vector)
}

## Fun��o que navega para a p�gina do i-�simo programa e extra� as informa��es de interesse :
navigate.to_pages <- function(page.count) {
  
  ## Interage com todas p�ginas :
  for (j in 1:page.count) {
    
    aux.page_count <- calculate.pages()
    xpaths.selectors <- paste0('//*[@id="form:j_idt63"]/span[2]/div/div/table/tbody/tr[',1:50,']/td[5]/a')
    xpaths.links <- extract.links(xpaths.selectors)
    
    ## Vari�vel auxiliar :
    temp.program_table <- list()
    
    ## Interage com todos os links desta p�gina :
    for (i in 1:length(xpaths.links)) {
      rd$navigate(xpaths.links[i])
      Sys.sleep(4)
      paste0("Programa ",i," da p�gina ",page.count) %>% print()
    
      ## Extrai o c�digo de identifica��o do programa :
      temp.program_id <- rd$getPageSource() %>% 
        unlist() %>%
        read_html() %>%
        html_node(xpath = '//*[@id="form"]/div/div/div/div/fieldset/div[2]/div[2]') %>%
        as.character()
      
      ## Extrai a tabela com a nota final do programa :
      temp.program_table[[i]] <- rd$getPageSource() %>% 
        unlist() %>%
        read_html() %>%
        html_table('#form\\:j_idt149\\:content > table:nth-child(1)', header = T, trim = T, dec = ".")
      
      temp.program_table[[i]] <- temp.program_table[[i]][14] %>% as.data.frame()
    
      ## Lista com todas as informa��es 
      Sucupira.Data[[j]][i] <- list("Pagina" = page.count, "ID" = temp.program_id, "Nota_Final" = temp.program_table)
      
    }
    
    ## Uma vez scrapeados todos os links da j-�sima p�gina, for�amos o selenium 
    ## retornar � p�gina inicial do SUCUPIRA :
    rd$navigate("https://sucupira.capes.gov.br/sucupira/public/consultas/avaliacao/consultaFichaAvaliacao.jsf")
    Sys.sleep(4)
    
    ## Interage com o campo Per�odo de Avalia��o :
    we <- rd$findElement(using = "css", "#form\\:periodoAvaliacao")
    we$clickElement()
    we$sendKeysToElement(list(key="down_arrow",key="return")) 
    Sys.sleep(4)
    
    ## Interage com o campo �rea de Avalia��o :
    we <- rd$findElement(using = "css", "#form\\:autocompleteAreaAv\\:input")
    we$clickElement()
    we$sendKeysToElement(list("MATEMATICA / PROBABILIDADE E ESTATISTICA"))
    Sys.sleep(4)
    
    ## Clicka mais uma vez no anterior para fazer sumir a caixinha expandida em �rea de Avalia��o :
    we <- rd$findElement(using = "css", "#form\\:autocompleteAreaAv\\:listbox")
    we$clickElement()
    
    ## Interage com o campo "Modalidade" :
    we <- rd$findElement(using = "css", "#form\\:idModalidade")
    we$clickElement()
    we$sendKeysToElement(list(key="down_arrow", key="return"))
    
    ## Interage com o bot�o consultar :
    we <- rd$findElement(using = "xpath", '//*[@id="form:consultar"]')
    we$clickElement()
    Sys.sleep(2)
    
    ## Clickar no bot�o da pr�xima p�gina 'j-1' vezes :
    sapply(c(1:j), function(k) {
      we <- rd$findElement(using = "xpath", '//*[@id="form:j_idt87:botaoProxPagina"]')
      we$clickElement()
      Sys.sleep(2)
    })
    
  } 
  
}


## Programa Principal :


## Incializa o Selenium :
rs <<- rsDriver(browser = "firefox", port = 4444L)
rd <<- rs$client

## Navega para a p�gina principal do SUCUPIRA :
rd$navigate("https://sucupira.capes.gov.br/sucupira/public/consultas/avaliacao/consultaFichaAvaliacao.jsf")
Sys.sleep(4)

## Interage com o campo Per�odo de Avalia��o :
we <- rd$findElement(using = "css", "#form\\:periodoAvaliacao")
we$clickElement()
we$sendKeysToElement(list(key="down_arrow",key="return")) 
Sys.sleep(4)

## Interage com o campo �rea de Avalia��o :
we <- rd$findElement(using = "css", "#form\\:autocompleteAreaAv\\:input")
we$clickElement()
we$sendKeysToElement(list("MATEMATICA / PROBABILIDADE E ESTATISTICA")) #Exemplo
Sys.sleep(4)

## Clicka mais uma vez no anterior para fazer sumir a caixinha expandida em �rea de Avalia��o :
we <- rd$findElement(using = "css", "#form\\:autocompleteAreaAv\\:listbox")
we$clickElement()

## Interage com o campo "Modalidade" :
we <- rd$findElement(using = "css", "#form\\:idModalidade")
we$clickElement()
we$sendKeysToElement(list(key="down_arrow", key="return"))

## Interage com o bot�o consultar :
we <- rd$findElement(using = "xpath", '//*[@id="form:consultar"]')
we$clickElement()
Sys.sleep(2)

## Aqui ficar�o guardadas todas as nossas informa��es de interesse :
Sucupira.Data <<- list()
n.pages <- calculate.pages()
navigate.to_pages(page.count = n.pages$N_paginas)



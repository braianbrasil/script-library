## Novo Script de remissão
        filtros = {
          imprimir_apenas: true,
          atraso: 3,
          operadores: ['mikro_market_emporio_express_m'],
          data_min: Time.zone.local(2026, 3, 1, 0, 0, 0),
          data_max: Time.zone.local(2026, 3, 26, 23, 59, 59),
          estados: [],
          pendente: true,
          desabilitada: false,
          evitar_circuito: true,
          sincronizar_estrategia: true,
          ids_notas: [],
          ids_instalacoes: [],
          ids_instalacoes_ignorar: [],
          exibir: {
            ids: true,
            produtos_com_erro: true
          },
          reemitir: {
            evitar_produtos_com_erro_fiscal: true
          },
          considerar_todos_operadores: false
        }
        
        require 'logger'
        require 'io/console'
        require 'time'
        
        $invoice_translations = {
          0 => "Pendente",
          1 => "Emitindo...",
          2 => "Emitida",
          3 => "Falha",
          4 => "Erro",
          5 => "Não pode emitir",
          6 => "Homologação",
          7 => "Desabilitada",
          8 => "Cancelada"
        }
        
        $invoice_error_translations = {
          "não possui código NCM cadastrado" => "Não possui código NCM cadastrado",
          "NCM inexistente" => "NCM inexistente",
          "não possui operação fiscal cadastrada" => "Não possui operação fiscal cadastrada",
          "OpenCircuitError" => "Circuitbox",
          "Net::OpenTimeout" => "Net::OpenTimeout",
          "Erro HTTP 5xx na emissão SAT" => "Erro HTTP 5xx na emissão SAT",
          "Sidekiq::Shutdown" => "Sidekiq::Shutdown",
          "NFC-e com CFOP" => "NFC-e com CFOP",
          "Codigo de Hash no QR-Code difere do calculado" => "Codigo de Hash no QR-Code difere do calculado",
          "CFOP nao permitido para o CST" => "CFOP nao permitido para o CST",
          "Duplicidade de NF-e" => "Duplicidade de NF-e com diferença na Chave de Acesso",
          "Nenhuma forma de pagamento para a nota fiscal" => "Nenhuma forma de pagamento para a nota fiscal",
          "não possui produto" => "Item sem produto",
          "Nota fiscal em emissão" => "Nota fiscal em emissão",
          "CSOSN invalido para emitente MEI" => "CSOSN invalido para emitente MEI",
          "Certificado Assinatura - erro Cadeia de Certificação" => "Certificado Assinatura - erro Cadeia de Certificação",
          "Certificado vencido" => "Certificado vencido",
          "Codigo Regime Tributario do emitente diverge do cadastro na SEFAZ" => "Codigo Regime Tributario do emitente diverge do cadastro na SEFAZ",
          "Emissor nao habilitado para emissao da NF-e/NFC-e" => "Emissor nao habilitado para emissao da NF-e/NFC-e",
          "Nenhum auth_token configurado" => "Nenhum auth_token configurado na Focus",
          "ICMS CST não implementado" => "ICMS CST não implementado",
          "Falha no reconhecimento da autoria ou integridade do arquivo digital" => "Falha no reconhecimento da autoria ou integridade do arquivo digital",
          "Item com CSOSN indevido" => "Item com CSOSN indevido",
          "Erro na validação do Schema XML" => "Erro na validação do Schema XML",
          "CST nao corresponde ao tipo de codigo de beneficio fiscal." => "CST nao corresponde ao tipo de codigo de beneficio fiscal",
          "This element is not expected" => "Elemento não esperado no JSON da nota",
          "Erro na Chave de Acesso - Campo Id nao corresponde" => "Campo Id nao corresponde a concatenacao dos campos correspondentes",
          "Chave de Acesso invalida (Ano menor que 05 ou Ano maior que Ano corrente)" => "Chave de Acesso invalida (Ano menor que 05 ou Ano maior que Ano corrente)"
        }
        
        def suprimir_logs_jobs
          original_sidekiq_logger = Sidekiq.logger
          original_active_job_logger = ActiveJob::Base.logger
        
          Sidekiq.logger = Logger.new(nil)
          ActiveJob::Base.logger = Logger.new(nil)
        
          yield
        ensure
          Sidekiq.logger = original_sidekiq_logger
          ActiveJob::Base.logger = original_active_job_logger
        end
        
        class BarraDeProgresso
          def initialize(total)
            @total = total
            @atual = 0
            @inicio = nil
            @ultimo_update = nil
            @atraso = nil
            @largura = IO.console.winsize[1] || 60
            @largura_barra = @largura - 80
          end
        
          def atualizar(processados, atraso)
            @atual = processados
            @inicio ||= Time.now
            @ultimo_update ||= @inicio
            tempo_decorrido = Time.now - @inicio
            @atraso = atraso if @atual > 1
            tempo_por_item = tempo_decorrido / @atual
            tempo_restante = [tempo_por_item * (@total - @atual), 0].max
            percentual = (@atual * 100 / @total).to_i
            preenchido = (percentual * @largura_barra / 100).to_i
            vazio = @largura_barra - preenchido
            cor = percentual < 50 ? 31 : 32
            barra_colorida = "\e[#{cor}m#{'━' * preenchido}\e[0m"
            barra_cinza = vazio > 0 ? " \e[90m#{'━' * vazio}\e[0m" : ""
            print "\r#{barra_colorida}#{barra_cinza} #{percentual}% | \e[#{cor}m#{@atual} de #{@total}\e[0m | decorrido: #{formatar_tempo(tempo_decorrido).blue} | restante: #{formatar_tempo(tempo_restante).yellow}"
            $stdout.flush
            @ultimo_update = Time.now
          end
        
          private def formatar_tempo(segundos)
            horas = (segundos / 3600).to_i
            minutos = ((segundos % 3600) / 60).to_i
            segundos = (segundos % 60).to_i
            tempo_str = ""
            tempo_str += "#{horas}h " if horas > 0
            tempo_str += "#{minutos}m " if minutos > 0
            tempo_str += "#{segundos}s"
            tempo_str.strip
          end
        end
        
        def texto_link(texto, url, icone: true)
          simbolo = icone ? '↗' : ''
          espaco = icone ? ' ' : ''
          "\e]8;;#{url}\a\e[34m\e[1m#{texto}#{espaco}#{simbolo}\e[0m\e]8;;\a"
        end
        
        $produtos_com_erro_fiscal = []
        
        def consultar_notas(filtros)
          system('clear')
          operadores = filtros[:operadores]
          data_min = filtros[:data_min]
          data_max = filtros[:data_max]
          estados = filtros[:estados]
          filtros[:pendente] ? estados << 0 : estados.delete(0)
          filtros[:desabilitada] ? estados << 7 : estados.delete(7)
          ids_notas = filtros[:ids_notas] || []
          ids_instalacoes = filtros[:ids_instalacoes] || []
          ids_instalacoes_ignorar = filtros[:ids_instalacoes_ignorar] || []
          erros_filtrados = filtros[:erros_filtrados] || []
          imprimir_apenas = filtros[:imprimir_apenas]
          considerar_todos_operadores = (defined?(filtros[:considerar_todos_operadores]) && filtros[:considerar_todos_operadores] == true)
        
          operadores.each_with_index do |filtro, indice|
            $produtos_com_erro_fiscal = []
            operador = filtro.is_a?(Integer) ? Operator.find(filtro) : Operator.find_by(label: filtro)
            if considerar_todos_operadores == true
              puts "Consultando " + "TODOS".red + " os operadores da base VMtecnologia"
            else
              puts "Operador: " + texto_link(operador.name, "https://vmpay.vertitecnologia.com.br/#{operador.label}/reports/invoices")  
            end
            
            puts "Estados: ".blue + estados.map { |s| "[#{$invoice_translations[s]}]" }.join(", ")
            puts "Período: ".blue + "[ #{data_min.strftime('%d/%m/%Y %H:%M:%S')} ]" + " - " + "[ #{data_max.strftime('%d/%m/%Y %H:%M:%S')} ]"
        
            notas = Invoice
            notas = notas.where(id: ids_notas) if ids_notas.any?
            notas = notas.where(installation_id: ids_instalacoes) if ids_instalacoes.any?
            notas = notas.where.not(location_id: ids_instalacoes_ignorar) if ids_instalacoes_ignorar.any?
            notas = notas.where(operator_id: operador.id) if considerar_todos_operadores == false
            notas = notas.force_index(:index_invoices_on_occurred_at_and_operator_id)
            .where(status: estados)
            .where('occurred_at BETWEEN ? AND ?', data_min, data_max)
            .order(occurred_at: :desc)
        
            begin
              grupos = notas.group_by do |nota|
                erro_emissao = nota.issuing_errors.join
                chave = $invoice_error_translations.keys.find { |k| erro_emissao.include?(k) }
                if chave
                  $invoice_error_translations[chave]
                else
                  if erro_emissao.strip.empty? || erro_emissao.nil?
                    log = InvoiceLog.find_by(invoice_id: nota.id)
                    if log.present?
                      dados = log.data || {}
                      corpo = dados.dig(:issuing, :response, :parsed_body)
                      if corpo.is_a?(Hash)
                        msg = corpo[:mensagem].presence || corpo[:mensagem_sefaz].presence
                      else
                        msg = corpo.to_s.presence
                      end
                      erro_vm = (dados.dig(:issuing, :invoice_errors) || []).first
                      resultado = (msg || erro_vm || "").to_s.strip.gsub(/\s+/, ' ')
                      chave = $invoice_error_translations.keys.find { |k| resultado.include?(k) }
                      (chave || msg || erro_vm || "").to_s.strip.gsub(/\s+/, ' ')
                    else
                      ""
                    end
                  else
                    erro_emissao
                  end
                end
              end
            rescue StandardError => e
              puts "Erro: #{e.message}"
            end
        
            resultado = grupos.transform_values { |v| { quantidade: v.size, ids: v.map(&:id), notas: v.map { |n| { id: n.id, operator_id: n.operator_id } } } }
            resultado.select! { |erro, _| erros_filtrados.any? { |f| erro.include?(f) } } if erros_filtrados.any?
            ids_agrupados = resultado.values.flat_map { |v| v[:ids] }
        
            if imprimir_apenas
              puts
              puts "Total de notas: #{notas.count}"
              puts
              resultado.sort_by { |(_, dados)| -dados[:quantidade] }.each do |erro, dados|
                puts "Erro: ".red + "\"#{erro}\"".blue
                puts "Quantidade: ".red + "#{dados[:quantidade]}"
                if filtros[:exibir][:ids]
                  operadores = Operator.where(id: dados[:notas].map { |n| n[:operator_id] }.uniq).index_by(&:id)
                  links = dados[:notas].map { |n| texto_link(n[:id], "https://vmpay.vertitecnologia.com.br/#{operadores[n[:operator_id]].label}/invoices/#{n[:id]}", icone: false) }
                  puts "IDs: ".yellow + links.join(',')
                end
                puts
              end
        
              puts "Deseja reemitir as notas apresentadas? (" + "s".green + "/" + "n".red +  ")"
              resposta = gets.chomp.downcase
        
              if resposta == "s"
                reemitir_notas(ids_agrupados, operador, filtros)
              end
            else
              reemitir_notas(ids_agrupados, operador, filtros)
            end
        
            puts "#" * 20 if (indice + 1) < operadores.size
          end;nil;
        end
        
        def reemitir_notas(ids_notas, operador, filtros)
          barra = BarraDeProgresso.new(ids_notas.size)
          puts "#{ids_notas.size} notas encontradas.".blue
          sleep(5) if ids_notas.size > 0
        
          ids_notas.each_with_index do |id, i|
            nota = Invoice.find(id)
            ActiveRecord::Base.connection.execute("SELECT 1")
            barra.atualizar(i + 1, filtros[:atraso])
            proximo = false
        
            if filtros[:evitar_circuito] && nota.issuing_errors.join[0, 63].include?('Circuitbox')
              proximo = true
            end
        
            unless proximo
              if filtros[:pendente]
                nota.update_attribute('status', 4)
                nota.reload
              end
        
              if filtros[:desabilitada]
                instalacao = Installation.find(nota.installation_id)
                if instalacao&.issues_invoice
                  nota.update_attribute('status', 4)
                  nota.reload
                else
                  nota.update_attribute('status', 7)
                  next
                end
              end
        
              nota_tem_produto_com_erro = false
              produtos_com_erro_nota = []
        
              if filtros[:reemitir][:evitar_produtos_com_erro_fiscal]
                items = InvoiceItem.where(invoice_id: nota.id);nil;
                if items.any?
                  lista_id_produtos = items.pluck(:good_id)
                  produtos = Good.where(id: lista_id_produtos)
                  if produtos.any?
                    produtos.each do |produto|
                      if (produto.ncm_code.nil? || produto.ncm_code.strip == '') || (produto.tax_operation_id.nil?) || (operador.enable_upc_code_invoice && (produto.upc_code.nil? || produto.upc_code.strip == ''))
                        nota_tem_produto_com_erro = true
                        produtos_com_erro_nota << produto.id unless produtos_com_erro_nota.include?(produto.id)
                      end
                    end;nil;
                  else
                    nota_tem_produto_com_erro = true
                  end
                else
                  nota_tem_produto_com_erro = true
                end
              end
        
              unless nota_tem_produto_com_erro
                suprimir_logs_jobs do
                  nota.update(issuing_strategy: operador.invoice_issuing_strategy) if operador.invoice_issuing_strategy != nota.issuing_strategy && filtros[:sincronizar_estrategia]
                  ReissueInvoiceJob.perform_later(nota.id)
                end
                sleep(filtros[:atraso])
              else
                if filtros[:exibir][:produtos_com_erro]
                  $produtos_com_erro_fiscal |= produtos_com_erro_nota
                end
              end
            end
          end;nil;
        
          if filtros[:exibir][:produtos_com_erro]
            puts "\n" * 2
            puts "Produtos (good_id) com cadastro incompleto para emissão de nota:".blue
            if $produtos_com_erro_fiscal.any?
              puts "#{$produtos_com_erro_fiscal}".red
            else
              puts "Nenhum".green
            end
          end
        end
        
        consultar_notas(filtros)
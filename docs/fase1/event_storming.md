# Event Storming — Oficina Mecânica

> Diagrama completo dos 4 bounded contexts. Renderiza em qualquer ferramenta que suporte Mermaid (GitHub, Notion, VS Code, mermaid.live).
>
> **Última atualização:** 2026-04-12

## Visão geral dos contextos

```
          ┌───────────────┐
          │   CADASTROS   │  ◄── OsFinalizada (atualiza km)
          │  (supporting) │
          │ Cliente,       │
          │ Veículo,       │
          │ Serviço        │
          └───────┬───────┘
                  │ Dados-mestre (read models)
     ┌────────────┼────────────┐
     ▼            ▼            ▼
┌─────────┐  ┌─────────┐  ┌─────────┐
│ ORDENS  │  │ ORÇA-   │  │ ESTOQUE │
│   DE    │──│ MENTOS  │──│(support)│
│ SERVIÇO │  │         │  │         │
│ (core)  │  │ (core)  │  │         │
└─────────┘  └─────────┘  └─────────┘
      │            │            ▲
      │ OsDiag-    │ Orçamento  │ Orçamento
      │ nosticada  │ Aprovado   │ Aprovado
      └──────►─────┘──►────────►┘
```

---

## Bounded Context: ORDEM DE SERVIÇO (core)

```mermaid
flowchart LR
    %% ========== ATORES ==========
    Atendente((Atendente))
    Mecanico((Mecânico))
    SistemaOS((Sistema))

    %% ========== AGREGADO ==========
    subgraph OS["`**AG: Ordem de Serviço**`"]
        direction TB

        CriaOS[CMD: Cria OS]
        AssumeOS[CMD: Mecânico assume OS]
        AddItens[CMD: Adiciona peças e serviços na OS]
        DiagOS[CMD: Atualiza OS para diagnosticada]
        AprovaOS[CMD: Aprova OS]
        ReprovaOS[CMD: Reprova OS]
        NotifMec[CMD: Notifica mecânico]
        ExecServ[CMD: Executa serviço]
        FinalizaOS[CMD: Finaliza OS]
        NotifCli[CMD: Notifica cliente]

        EvCriada(EV: OS Criada)
        EvAssumida(EV: OS Assumida)
        EvItensAdd(EV: Peças/Serviços Adicionados à OS)
        EvDiag(EV: OS Diagnosticada)
        EvAprov(EV: OS Aprovada)
        EvReprov(EV: OS Reprovada)
        EvMecNotif(EV: Mecânico Notificado)
        EvExec(EV: Serviço Executado)
        EvFinal(EV: OS Finalizada)
        EvCliNotif(EV: Cliente Notificado)

        CriaOS --> EvCriada
        AssumeOS --> EvAssumida
        AddItens --> EvItensAdd
        DiagOS --> EvDiag
        AprovaOS --> EvAprov
        ReprovaOS --> EvReprov
        NotifMec --> EvMecNotif
        ExecServ --> EvExec
        FinalizaOS --> EvFinal
        NotifCli --> EvCliNotif
    end

    %% ========== ATORES → COMANDOS ==========
    Atendente --> CriaOS
    Mecanico --> AssumeOS
    Mecanico --> AddItens
    Mecanico --> DiagOS
    SistemaOS --> AprovaOS
    SistemaOS --> ReprovaOS
    SistemaOS --> NotifMec
    Mecanico --> ExecServ
    Mecanico --> FinalizaOS
    SistemaOS --> NotifCli

    %% ========== READ MODEL ==========
    RMAprov[/"ML: Lista de OS aprovadas"/]
    EvAprov -.-> RMAprov
    RMAprov -.-> NotifMec

    %% ========== POLÍTICA: sai para Orçamentos ==========
    PolOrc[/"POL: Criação do Orçamento"/]
    EvDiag --> PolOrc

    %% ========== ENTRADA: volta de Orçamentos ==========
    OrcAprovado(["`EV de **Orçamento**:
    Orçamento Aprovado`"])
    OrcReprovado(["`EV de **Orçamento**:
    Orçamento Reprovado`"])
    PolMudaStatusAprov[/"POL: OS muda status
    para Em Execução"/]
    PolMudaStatusReprov[/"POL: OS muda status
    para Reprovada"/]
    OrcAprovado --> PolMudaStatusAprov --> AprovaOS
    OrcReprovado --> PolMudaStatusReprov --> ReprovaOS

    %% ========== SAÍDA: para Cadastros ==========
    PolKm[/"POL: Atualiza quilometragem
    do veículo"/]
    EvFinal --> PolKm

    classDef cmd fill:#9bb8ff,stroke:#5470c6,color:#000
    classDef evt fill:#ffe88c,stroke:#c99a00,color:#000
    classDef pol fill:#d6a6ff,stroke:#8a2be2,color:#000
    classDef rm fill:#a8e6a2,stroke:#2d8a1f,color:#000
    classDef actor fill:#ffd38c,stroke:#e58e00,color:#000
    classDef cross fill:#ffcccc,stroke:#cc4444,color:#000

    class CriaOS,AssumeOS,AddItens,DiagOS,AprovaOS,ReprovaOS,NotifMec,ExecServ,FinalizaOS,NotifCli cmd
    class EvCriada,EvAssumida,EvItensAdd,EvDiag,EvAprov,EvReprov,EvMecNotif,EvExec,EvFinal,EvCliNotif evt
    class PolOrc,PolMudaStatusAprov,PolMudaStatusReprov,PolKm pol
    class RMAprov rm
    class Atendente,Mecanico,SistemaOS actor
    class OrcAprovado,OrcReprovado cross
```

### Status da OS

```
Recebida → Em diagnóstico → Aguardando aprovação → Em execução → Finalizada → Entregue
   │              │                   │                  │             │           │
 Cria OS    Mecânico assume    Orçamento enviado    Cliente      Mecânico     Veículo
             e diagnostica      ao cliente          aprova       finaliza     devolvido
```

---

## Bounded Context: ORÇAMENTO (core)

```mermaid
flowchart LR
    SistemaOrc((Sistema))
    Cliente((Cliente))

    subgraph ORC["`**AG: Orçamento**`"]
        direction TB

        CriaOrc[CMD: Cria Orçamento]
        EnviaOrc[CMD: Envia Orçamento]
        AprovaOrc[CMD: Aprova Orçamento]
        ReprovaOrc[CMD: Reprova Orçamento]

        EvOrcCriado(EV: Orçamento Criado)
        EvOrcEnviado(EV: Orçamento Enviado ao Cliente)
        EvOrcAprovado(EV: Orçamento Aprovado)
        EvOrcReprovado(EV: Orçamento Reprovado)

        CriaOrc --> EvOrcCriado
        EnviaOrc --> EvOrcEnviado
        AprovaOrc --> EvOrcAprovado
        ReprovaOrc --> EvOrcReprovado
    end

    SistemaOrc --> CriaOrc
    SistemaOrc --> EnviaOrc
    Cliente --> AprovaOrc
    Cliente --> ReprovaOrc

    %% ========== ENTRADA: de OS ==========
    OsDiag(["`EV de **OS**:
    OS Diagnosticada`"])
    OsDiag --> CriaOrc

    %% ========== POLÍTICA: soma peças e serviços ==========
    PolSoma[/"POL: Soma todos os
    serviços e peças"/]
    EvOrcCriado --> PolSoma

    %% ========== SAÍDA: para OS ==========
    PolOsAprov[/"POL: OS muda status"/]
    EvOrcAprovado --> PolOsAprov

    %% ========== SAÍDA: para Estoque ==========
    PolEstoque[/"POL: Baixa quantidade
    de peças no estoque"/]
    EvOrcAprovado --> PolEstoque

    %% ========== SAÍDA: OS reprovada ==========
    PolOsReprov[/"POL: OS muda status
    para Reprovada"/]
    EvOrcReprovado --> PolOsReprov

    classDef cmd fill:#9bb8ff,stroke:#5470c6,color:#000
    classDef evt fill:#ffe88c,stroke:#c99a00,color:#000
    classDef pol fill:#d6a6ff,stroke:#8a2be2,color:#000
    classDef actor fill:#ffd38c,stroke:#e58e00,color:#000
    classDef cross fill:#ffcccc,stroke:#cc4444,color:#000

    class CriaOrc,EnviaOrc,AprovaOrc,ReprovaOrc cmd
    class EvOrcCriado,EvOrcEnviado,EvOrcAprovado,EvOrcReprovado evt
    class PolSoma,PolOsAprov,PolEstoque,PolOsReprov pol
    class SistemaOrc,Cliente actor
    class OsDiag cross
```

---

## Bounded Context: ESTOQUE (supporting — simplificado)

```mermaid
flowchart LR
    Admin((Admin))
    SistemaEst((Sistema))

    subgraph ESTOQUE["`**AG: Item de Estoque**`"]
        direction TB

        CadItem[CMD: Cadastrar Item]
        AtuItem[CMD: Atualizar Item]
        AddQtd[CMD: Adicionar Quantidade]
        BaixaQtd[CMD: Baixar Quantidade]

        EvCad(EV: Item Cadastrado)
        EvAtu(EV: Item Atualizado)
        EvAdd(EV: Quantidade Adicionada)
        EvBaixa(EV: Quantidade Baixada)
        EvInsuf(EV: Estoque Insuficiente)

        CadItem --> EvCad
        AtuItem --> EvAtu
        AddQtd --> EvAdd
        BaixaQtd --> EvBaixa
    end

    Admin --> CadItem
    Admin --> AtuItem
    Admin --> AddQtd
    SistemaEst --> BaixaQtd

    %% ========== ENTRADA: de Orçamento ==========
    OrcAprov(["`EV de **Orçamento**:
    Orçamento Aprovado`"])
    PolBaixa[/"POL: Para cada peça do
    orçamento, baixar quantidade"/]
    OrcAprov --> PolBaixa --> BaixaQtd

    %% ========== POLÍTICA INTERNA: alerta ==========
    PolAlerta[/"POL: Se quantidade < limite
    mínimo, disparar alerta"/]
    EvBaixa --> PolAlerta -.-> EvInsuf

    classDef cmd fill:#9bb8ff,stroke:#5470c6,color:#000
    classDef evt fill:#ffe88c,stroke:#c99a00,color:#000
    classDef pol fill:#d6a6ff,stroke:#8a2be2,color:#000
    classDef actor fill:#ffd38c,stroke:#e58e00,color:#000
    classDef cross fill:#ffcccc,stroke:#cc4444,color:#000

    class CadItem,AtuItem,AddQtd,BaixaQtd cmd
    class EvCad,EvAtu,EvAdd,EvBaixa,EvInsuf evt
    class PolBaixa,PolAlerta pol
    class Admin,SistemaEst actor
    class OrcAprov cross
```

---

## Bounded Context: CADASTROS (supporting)

```mermaid
flowchart LR
    AtendenteCad((Atendente))
    AdminCad((Admin))
    SistemaCad((Sistema))

    subgraph CLIENTE["`**AG: Cliente**`"]
        direction TB
        CadCli[CMD: Cadastrar Cliente]
        AtuCli[CMD: Atualizar Cliente]
        InaCli[CMD: Inativar Cliente]

        EvCliCad(EV: Cliente Cadastrado)
        EvCliAtu(EV: Cliente Atualizado)
        EvCliIna(EV: Cliente Inativado)

        CadCli --> EvCliCad
        AtuCli --> EvCliAtu
        InaCli --> EvCliIna
    end

    subgraph VEICULO["`**AG: Veículo**`"]
        direction TB
        CadVei[CMD: Cadastrar Veículo]
        AtuVei[CMD: Atualizar Veículo]
        AtuKm[CMD: Atualizar Quilometragem]

        EvVeiCad(EV: Veículo Cadastrado)
        EvVeiAtu(EV: Veículo Atualizado)
        EvKmAtu(EV: Quilometragem Atualizada)

        CadVei --> EvVeiCad
        AtuVei --> EvVeiAtu
        AtuKm --> EvKmAtu
    end

    subgraph SERVICO["`**AG: Serviço (catálogo)**`"]
        direction TB
        CadServ[CMD: Cadastrar Serviço]
        AtuServ[CMD: Atualizar Serviço]

        EvServCad(EV: Serviço Cadastrado)
        EvServAtu(EV: Serviço Atualizado)

        CadServ --> EvServCad
        AtuServ --> EvServAtu
    end

    AtendenteCad --> CadCli
    AtendenteCad --> AtuCli
    AtendenteCad --> InaCli
    AtendenteCad --> CadVei
    AtendenteCad --> AtuVei
    AdminCad --> CadServ
    AdminCad --> AtuServ
    SistemaCad --> AtuKm

    %% ========== POLÍTICA INTERNA ==========
    PolInaVei[/"POL: Ao inativar cliente,
    inativar veículos"/]
    EvCliIna --> PolInaVei

    %% ========== ENTRADA: de OS ==========
    OsFinal(["`EV de **OS**:
    OS Finalizada`"])
    PolAtuKm[/"POL: Atualiza quilometragem
    do veículo"/]
    OsFinal --> PolAtuKm --> AtuKm

    %% ========== READ MODELS ==========
    RMCli[/"ML: Dados do Cliente"/]
    RMVei[/"ML: Veículos do Cliente"/]
    RMServ[/"ML: Catálogo de Serviços"/]
    EvCliCad -.-> RMCli
    EvVeiCad -.-> RMVei
    EvServCad -.-> RMServ

    classDef cmd fill:#9bb8ff,stroke:#5470c6,color:#000
    classDef evt fill:#ffe88c,stroke:#c99a00,color:#000
    classDef pol fill:#d6a6ff,stroke:#8a2be2,color:#000
    classDef rm fill:#a8e6a2,stroke:#2d8a1f,color:#000
    classDef actor fill:#ffd38c,stroke:#e58e00,color:#000
    classDef cross fill:#ffcccc,stroke:#cc4444,color:#000

    class CadCli,AtuCli,InaCli,CadVei,AtuVei,AtuKm,CadServ,AtuServ cmd
    class EvCliCad,EvCliAtu,EvCliIna,EvVeiCad,EvVeiAtu,EvKmAtu,EvServCad,EvServAtu evt
    class PolInaVei,PolAtuKm pol
    class RMCli,RMVei,RMServ rm
    class AtendenteCad,AdminCad,SistemaCad actor
    class OsFinal cross
```

---

## Legenda

| Cor | Elemento | Descrição |
|---|---|---|
| 🔵 Azul | CMD | Comando (ação que alguém ou algo dispara) |
| 🟡 Amarelo | EV | Evento de domínio (fato que aconteceu) |
| 🟣 Roxo | POL | Política (reação automática a um evento) |
| 🟢 Verde | ML | Read Model (projeção de leitura) |
| 🟠 Laranja | Actor | Quem dispara o comando |
| 🔴 Vermelho claro | Cross-ctx | Evento vindo de outro bounded context |

## Fluxos cross-context (resumo)

```
OsDiagnosticada ──────────→ Orçamento: cria orçamento

OrcamentoAprovado ────────→ OS: muda status para "Em execução"
                  ────────→ Estoque: baixa quantidade das peças

OrcamentoReprovado ───────→ OS: muda status para "Reprovada"

OsFinalizada ─────────────→ Cadastros: atualiza quilometragem do veículo
```

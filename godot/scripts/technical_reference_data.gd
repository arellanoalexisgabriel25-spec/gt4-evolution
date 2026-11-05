extends RefCounted

# Claims transcribed from the user's five-page compilation, not a checked
# manufacturer's sheet. Keep exact anchors separate from assumed curve RPMs,
# fuel/load mass convention, gearbox and the other development parameters.
const DOCUMENT := "Informe Técnico Automotriz Completo.pdf"
const DOCUMENT_SHA256 := "4aeb432f9ca26c72e09f39742fc1421921c5536286d9de40fac88a633934f1f0"
const FIAT_DOCUMENT := "Informe de Modelos Fiat.pdf"
const FIAT_DOCUMENT_SHA256 := "4e84a1068988c1fd721be6ff6a1da77bcedf8aa4efeae85416e1164d033e727a"
const VIVACE_REVISION := "vivace_14_bio_1997_021"
const VIVACE_MASS_KG := 807.0
const VIVACE_POWER_CV := 63.0
const VIVACE_TORQUE_KGFM := 10.4
const VIVACE_TORQUE_NM := VIVACE_TORQUE_KGFM*9.80665
const VIVACE_LENGTH_M := 3.742

static func compilation_source(page: int) -> Dictionary:
    return {"kind":"user_secondary_compilation","document":DOCUMENT,"page":page,"sha256":DOCUMENT_SHA256,"primary_document_verified":false}

static func fiat_source(page: int) -> Dictionary:
    return {"kind":"user_supplied_secondary_report","document":FIAT_DOCUMENT,"page":page,"sha256":FIAT_DOCUMENT_SHA256,"primary_document_verified":false}

static func vivace_sources() -> Array:
    return [
        {"kind":"user_compilation","document":DOCUMENT,"page":1,"sha256":DOCUMENT_SHA256,"primary_document_verified":false},
        fiat_source(3)
    ]

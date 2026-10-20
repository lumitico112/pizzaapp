import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pizzaapp/models/insumo.dart';

const _primaryOrange = Color(0xFFFF6A00);
const _secondaryRed = Color(0xFFD62828);
const _textDark = Color(0xFF1F2937);
const _textMuted = Color(0xFF6B7280);
const _mint = Color(0xFFECFDF5);
const _mintBorder = Color(0xFFA7F3D0);

/// Normaliza texto para busquedas tolerantes a mayusculas y acentos.
String normalizarBusqueda(String value) {
  const accents = {
    'á': 'a',
    'à': 'a',
    'ä': 'a',
    'â': 'a',
    'ã': 'a',
    'é': 'e',
    'è': 'e',
    'ë': 'e',
    'ê': 'e',
    'í': 'i',
    'ì': 'i',
    'ï': 'i',
    'î': 'i',
    'ó': 'o',
    'ò': 'o',
    'ö': 'o',
    'ô': 'o',
    'õ': 'o',
    'ú': 'u',
    'ù': 'u',
    'ü': 'u',
    'û': 'u',
    'ñ': 'n',
  };
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    buffer.write(accents[char] ?? char);
  }
  return buffer.toString().trim();
}

/// Filtra insumos activos por nombre, tipo o unidad.
///
/// El resultado prioriza coincidencias que empiezan por el texto buscado y
/// conserva el orden original para el resto.
List<Insumo> filtrarInsumos(
  List<Insumo> insumos,
  String query, {
  int limit = 10,
}) {
  final normalizedQuery = normalizarBusqueda(query);
  if (normalizedQuery.isEmpty) {
    return insumos.take(limit).toList();
  }

  final matches = insumos.where((insumo) {
    final nombre = normalizarBusqueda(insumo.nombre);
    final tipo = normalizarBusqueda(insumo.tipoInsumo);
    final unidad = normalizarBusqueda(insumo.unidadMedida);
    return nombre.contains(normalizedQuery) ||
        tipo.contains(normalizedQuery) ||
        unidad.contains(normalizedQuery);
  }).toList();

  matches.sort((a, b) {
    final aStarts = normalizarBusqueda(a.nombre).startsWith(normalizedQuery);
    final bStarts = normalizarBusqueda(b.nombre).startsWith(normalizedQuery);
    if (aStarts == bStarts) return 0;
    return aStarts ? -1 : 1;
  });

  return matches.take(limit).toList();
}

sealed class _InsumoSearchOption {
  const _InsumoSearchOption();
}

class _InsumoMatchOption extends _InsumoSearchOption {
  final Insumo insumo;

  const _InsumoMatchOption(this.insumo);
}

class _InsumoOcasionalOption extends _InsumoSearchOption {
  final String query;

  const _InsumoOcasionalOption(this.query);
}

/// Campo de busqueda con sugerencias para seleccionar un insumo existente.
///
/// Si no hay coincidencias muestra la accion "Registrar como compra ocasional".
/// La persistencia de esa accion pertenece a la siguiente fase.
class InsumoSearchField extends StatefulWidget {
  final List<Insumo> insumos;
  final int? selectedId;
  final TextEditingController textController;
  final FocusNode focusNode;
  final InputDecoration decoration;
  final TextStyle? style;
  final ValueChanged<Insumo> onSelected;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onRegistrarOcasional;

  const InsumoSearchField({
    super.key,
    required this.insumos,
    required this.selectedId,
    required this.textController,
    required this.focusNode,
    required this.decoration,
    required this.onSelected,
    required this.onQueryChanged,
    required this.onRegistrarOcasional,
    this.style,
  });

  @override
  State<InsumoSearchField> createState() => _InsumoSearchFieldState();
}

class _InsumoSearchFieldState extends State<InsumoSearchField> {
  final _fieldKey = GlobalKey<FormFieldState<String>>();

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant InsumoSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_handleTextChanged);
      widget.textController.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  void _validateAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fieldKey.currentState?.validate();
    });
  }

  void _clearSelection() {
    widget.textController.clear();
    widget.onQueryChanged('');
    _validateAfterFrame();
    widget.focusNode.requestFocus();
  }

  void _handleSelected(_InsumoSearchOption option) {
    switch (option) {
      case _InsumoMatchOption(:final insumo):
        widget.onSelected(insumo);
        widget.textController.value = TextEditingValue(
          text: insumo.nombre,
          selection: TextSelection.collapsed(offset: insumo.nombre.length),
        );
        _validateAfterFrame();
      case _InsumoOcasionalOption(:final query):
        widget.onRegistrarOcasional(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<_InsumoSearchOption>(
      textEditingController: widget.textController,
      focusNode: widget.focusNode,
      displayStringForOption: (option) => switch (option) {
        _InsumoMatchOption(:final insumo) => insumo.nombre,
        _InsumoOcasionalOption(:final query) => query,
      },
      optionsBuilder: (value) {
        final query = value.text.trim();
        final matches = filtrarInsumos(widget.insumos, query);
        if (matches.isEmpty && (query.isNotEmpty || widget.insumos.isEmpty)) {
          return <_InsumoSearchOption>[_InsumoOcasionalOption(query)];
        }
        return matches
            .map<_InsumoSearchOption>(_InsumoMatchOption.new)
            .toList();
      },
      onSelected: _handleSelected,
      optionsViewOpenDirection: OptionsViewOpenDirection.down,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          key: _fieldKey,
          controller: controller,
          focusNode: focusNode,
          style: widget.style,
          textInputAction: TextInputAction.search,
          autocorrect: false,
          decoration: widget.decoration.copyWith(
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar insumo',
                    onPressed: _clearSelection,
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: _textMuted,
                    ),
                  ),
          ),
          onChanged: widget.onQueryChanged,
          onFieldSubmitted: (_) => onFieldSubmitted(),
          validator: (_) {
            if (widget.selectedId == null) {
              return 'Seleccione un insumo de la lista';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final optionList = options.toList();
        final highlightedIndex = AutocompleteHighlightedOption.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 300,
                maxWidth: MediaQuery.sizeOf(context).width - 32,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: optionList.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  final highlighted = index == highlightedIndex;
                  return switch (option) {
                    _InsumoMatchOption(:final insumo) => ListTile(
                      key: ValueKey('insumo-option-${insumo.id}'),
                      selected: highlighted || insumo.id == widget.selectedId,
                      selectedTileColor: const Color(0xFFFFF5F2),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1ED),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: _secondaryRed,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        insumo.nombre,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${insumo.unidadMedida} · ${insumo.tipoInsumo}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: insumo.id == widget.selectedId
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: _primaryOrange,
                              size: 20,
                            )
                          : null,
                      onTap: () => onSelected(option),
                    ),
                    _InsumoOcasionalOption(:final query) => ListTile(
                      key: const ValueKey('compra-ocasional-option'),
                      selected: highlighted,
                      selectedTileColor: _mint,
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _mint,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _mintBorder),
                        ),
                        child: const Icon(
                          Icons.add_business_rounded,
                          color: Color(0xFF059669),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        'Registrar como compra ocasional',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      subtitle: Text(
                        query.isEmpty
                            ? 'No requiere control de inventario'
                            : 'No se encontró "$query" en el inventario',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _textMuted,
                        size: 14,
                      ),
                      onTap: () => onSelected(option),
                    ),
                  };
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

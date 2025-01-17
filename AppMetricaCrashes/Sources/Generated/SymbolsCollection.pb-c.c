/* Generated by the protocol buffer compiler.  DO NOT EDIT! */
/* Generated from: SymbolsCollection.proto */

/* Do not generate deprecated warnings for self */
#ifndef PROTOBUF_C__NO_DEPRECATED
#define PROTOBUF_C__NO_DEPRECATED
#endif

#include "SymbolsCollection.pb-c.h"
void   ama__symbols_collection__symbol__init
                     (Ama__SymbolsCollection__Symbol         *message)
{
  static const Ama__SymbolsCollection__Symbol init_value = AMA__SYMBOLS_COLLECTION__SYMBOL__INIT;
  *message = init_value;
}
void   ama__symbols_collection__image__init
                     (Ama__SymbolsCollection__Image         *message)
{
  static const Ama__SymbolsCollection__Image init_value = AMA__SYMBOLS_COLLECTION__IMAGE__INIT;
  *message = init_value;
}
void   ama__symbols_collection__init
                     (Ama__SymbolsCollection         *message)
{
  static const Ama__SymbolsCollection init_value = AMA__SYMBOLS_COLLECTION__INIT;
  *message = init_value;
}
size_t ama__symbols_collection__get_packed_size
                     (const Ama__SymbolsCollection *message)
{
  assert(message->base.descriptor == &ama__symbols_collection__descriptor);
  return protobuf_c_message_get_packed_size ((const ProtobufCMessage*)(message));
}
size_t ama__symbols_collection__pack
                     (const Ama__SymbolsCollection *message,
                      uint8_t       *out)
{
  assert(message->base.descriptor == &ama__symbols_collection__descriptor);
  return protobuf_c_message_pack ((const ProtobufCMessage*)message, out);
}
size_t ama__symbols_collection__pack_to_buffer
                     (const Ama__SymbolsCollection *message,
                      ProtobufCBuffer *buffer)
{
  assert(message->base.descriptor == &ama__symbols_collection__descriptor);
  return protobuf_c_message_pack_to_buffer ((const ProtobufCMessage*)message, buffer);
}
Ama__SymbolsCollection *
       ama__symbols_collection__unpack
                     (ProtobufCAllocator  *allocator,
                      size_t               len,
                      const uint8_t       *data)
{
  return (Ama__SymbolsCollection *)
     protobuf_c_message_unpack (&ama__symbols_collection__descriptor,
                                allocator, len, data);
}
void   ama__symbols_collection__free_unpacked
                     (Ama__SymbolsCollection *message,
                      ProtobufCAllocator *allocator)
{
  if(!message)
    return;
  assert(message->base.descriptor == &ama__symbols_collection__descriptor);
  protobuf_c_message_free_unpacked ((ProtobufCMessage*)message, allocator);
}
static const ProtobufCFieldDescriptor ama__symbols_collection__symbol__field_descriptors[5] =
{
  {
    "is_inctance_method",
    1,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_BOOL,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Symbol, is_inctance_method),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "class_name",
    2,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_BYTES,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Symbol, class_name),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "method_name",
    3,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_BYTES,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Symbol, method_name),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "address",
    4,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_UINT64,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Symbol, address),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "size",
    5,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_UINT32,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Symbol, size),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
};
static const unsigned ama__symbols_collection__symbol__field_indices_by_name[] = {
  3,   /* field[3] = address */
  1,   /* field[1] = class_name */
  0,   /* field[0] = is_inctance_method */
  2,   /* field[2] = method_name */
  4,   /* field[4] = size */
};
static const ProtobufCIntRange ama__symbols_collection__symbol__number_ranges[1 + 1] =
{
  { 1, 0 },
  { 0, 5 }
};
const ProtobufCMessageDescriptor ama__symbols_collection__symbol__descriptor =
{
  PROTOBUF_C__MESSAGE_DESCRIPTOR_MAGIC,
  "ama.SymbolsCollection.Symbol",
  "Symbol",
  "Ama__SymbolsCollection__Symbol",
  "ama",
  sizeof(Ama__SymbolsCollection__Symbol),
  5,
  ama__symbols_collection__symbol__field_descriptors,
  ama__symbols_collection__symbol__field_indices_by_name,
  1,  ama__symbols_collection__symbol__number_ranges,
  (ProtobufCMessageInit) ama__symbols_collection__symbol__init,
  NULL,NULL,NULL    /* reserved[123] */
};
static const ProtobufCFieldDescriptor ama__symbols_collection__image__field_descriptors[7] =
{
  {
    "uuid",
    1,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_BYTES,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Image, uuid),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "name",
    2,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_BYTES,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Image, name),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "cpu_type",
    3,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_UINT32,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Image, cpu_type),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "cpu_subtype",
    4,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_UINT32,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Image, cpu_subtype),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "address",
    5,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_UINT64,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Image, address),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "vm_address",
    6,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_UINT64,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Image, vm_address),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "size",
    7,
    PROTOBUF_C_LABEL_REQUIRED,
    PROTOBUF_C_TYPE_UINT32,
    0,   /* quantifier_offset */
    offsetof(Ama__SymbolsCollection__Image, size),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
};
static const unsigned ama__symbols_collection__image__field_indices_by_name[] = {
  4,   /* field[4] = address */
  3,   /* field[3] = cpu_subtype */
  2,   /* field[2] = cpu_type */
  1,   /* field[1] = name */
  6,   /* field[6] = size */
  0,   /* field[0] = uuid */
  5,   /* field[5] = vm_address */
};
static const ProtobufCIntRange ama__symbols_collection__image__number_ranges[1 + 1] =
{
  { 1, 0 },
  { 0, 7 }
};
const ProtobufCMessageDescriptor ama__symbols_collection__image__descriptor =
{
  PROTOBUF_C__MESSAGE_DESCRIPTOR_MAGIC,
  "ama.SymbolsCollection.Image",
  "Image",
  "Ama__SymbolsCollection__Image",
  "ama",
  sizeof(Ama__SymbolsCollection__Image),
  7,
  ama__symbols_collection__image__field_descriptors,
  ama__symbols_collection__image__field_indices_by_name,
  1,  ama__symbols_collection__image__number_ranges,
  (ProtobufCMessageInit) ama__symbols_collection__image__init,
  NULL,NULL,NULL    /* reserved[123] */
};
static const ProtobufCFieldDescriptor ama__symbols_collection__field_descriptors[3] =
{
  {
    "symbols",
    1,
    PROTOBUF_C_LABEL_REPEATED,
    PROTOBUF_C_TYPE_MESSAGE,
    offsetof(Ama__SymbolsCollection, n_symbols),
    offsetof(Ama__SymbolsCollection, symbols),
    &ama__symbols_collection__symbol__descriptor,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "images",
    2,
    PROTOBUF_C_LABEL_REPEATED,
    PROTOBUF_C_TYPE_MESSAGE,
    offsetof(Ama__SymbolsCollection, n_images),
    offsetof(Ama__SymbolsCollection, images),
    &ama__symbols_collection__image__descriptor,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
  {
    "dynamic_binary_names",
    3,
    PROTOBUF_C_LABEL_REPEATED,
    PROTOBUF_C_TYPE_BYTES,
    offsetof(Ama__SymbolsCollection, n_dynamic_binary_names),
    offsetof(Ama__SymbolsCollection, dynamic_binary_names),
    NULL,
    NULL,
    0,             /* flags */
    0,NULL,NULL    /* reserved1,reserved2, etc */
  },
};
static const unsigned ama__symbols_collection__field_indices_by_name[] = {
  2,   /* field[2] = dynamic_binary_names */
  1,   /* field[1] = images */
  0,   /* field[0] = symbols */
};
static const ProtobufCIntRange ama__symbols_collection__number_ranges[1 + 1] =
{
  { 1, 0 },
  { 0, 3 }
};
const ProtobufCMessageDescriptor ama__symbols_collection__descriptor =
{
  PROTOBUF_C__MESSAGE_DESCRIPTOR_MAGIC,
  "ama.SymbolsCollection",
  "SymbolsCollection",
  "Ama__SymbolsCollection",
  "ama",
  sizeof(Ama__SymbolsCollection),
  3,
  ama__symbols_collection__field_descriptors,
  ama__symbols_collection__field_indices_by_name,
  1,  ama__symbols_collection__number_ranges,
  (ProtobufCMessageInit) ama__symbols_collection__init,
  NULL,NULL,NULL    /* reserved[123] */
};

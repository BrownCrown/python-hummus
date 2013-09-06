# -*- coding: utf-8 -*-
from libcpp.string cimport string
from hummus.document cimport *
from hummus.utils cimport to_string
from hummus.interface cimport (
    PythonByteWriterWithPosition, ByteWriterWithPosition)
from hummus.stream import StreamByteWriterWithPosition


cdef class Document:
    cdef PDFWriter _handle
    cdef str _name
    cdef PythonByteWriterWithPosition* _stream

    def __cinit__(self, stream=None, *, str filename=None):
        cdef PythonByteWriterWithPosition* stream_handle = NULL
        cdef ByteWriterWithPosition base_writer

        # Ensure we have a stream or a filename.
        if stream is None and filename is None:
            raise ValueError("One of 'stream' or 'filename' must be given.")

        if stream is not None:
            # Construct a streaming writer.
            writer = StreamByteWriterWithPosition(stream)

            # Pull out the low-level handle.
            base_writer = <ByteWriterWithPosition>writer
            stream_handle = base_writer._handle

        # Store the filename or stream to save the document to.
        self._stream = stream_handle
        self._name = filename or ':memory:'

    def begin(self):
        """Begin operations on the PDF.
        """

        if self._stream:
            # Initiate the underlying PDF-Writer for streaming operation.
            self._handle.StartPDFForStream(self._stream, ePDFVersion17)

        else:
            # Initiate the underlying PDF-Writer for operations towards
            # a file.
            self._handle.StartPDF(to_string(self._name), ePDFVersion17)

    def __enter__(self):
        self.begin()
        return self

    def end(self):
        """End operations on the PDF.
        """

        if self._stream:
            # Terminate the streaming operations for the PDF-Writer.
            self._handle.EndPDFForStream()

        else:
            # Terminate the file operations for the PDF-W
            self._handle.EndPDF()

        # Reset the PDF-Writer for further operations.
        self._handle.Reset()

    def __exit__(self, *args):
        self.end()

    @property
    def name(self):
        """Get the name that this document is bound to.

        This returns the filename if the document is bound to a file or
        :memory: if it is bound to a stream.
        """
        return self._name
// RUN: mlir-opt -allow-unregistered-dialect -split-input-file -verify-diagnostics %s | FileCheck %s

spirv.module Logical GLSL450 requires #spirv.vce<v1.0, [Shader], []> {
  // CHECK-LABEL: @matrix_times_scalar_1
  spirv.func @matrix_times_scalar_1(%arg0 : !spirv.matrix<3 x vector<3xf32>>, %arg1 : f32) -> !spirv.matrix<3 x vector<3xf32>> "None" {
    // CHECK: {{%.*}} = spirv.MatrixTimesScalar {{%.*}}, {{%.*}} : !spirv.matrix<3 x vector<3xf32>>, f32
    %result = spirv.MatrixTimesScalar %arg0, %arg1 : !spirv.matrix<3 x vector<3xf32>>, f32
    spirv.ReturnValue %result : !spirv.matrix<3 x vector<3xf32>>
  }

  // CHECK-LABEL: @matrix_times_scalar_2
  spirv.func @matrix_times_scalar_2(%arg0 : !spirv.coopmatrix<16x16xf16, Subgroup, MatrixA>, %arg1 : f16) -> !spirv.coopmatrix<16x16xf16, Subgroup, MatrixA> "None" {
    // CHECK: {{%.*}} = spirv.MatrixTimesScalar {{%.*}}, {{%.*}} : !spirv.coopmatrix<16x16xf16, Subgroup, MatrixA>, f16
    %result = spirv.MatrixTimesScalar %arg0, %arg1 : !spirv.coopmatrix<16x16xf16, Subgroup, MatrixA>, f16
    spirv.ReturnValue %result : !spirv.coopmatrix<16x16xf16, Subgroup, MatrixA>
  }

  // CHECK-LABEL: @matrix_transpose_1
  spirv.func @matrix_transpose_1(%arg0 : !spirv.matrix<3 x vector<2xf32>>) -> !spirv.matrix<2 x vector<3xf32>> "None" {
    // CHECK: {{%.*}} = spirv.Transpose {{%.*}} : !spirv.matrix<3 x vector<2xf32>> -> !spirv.matrix<2 x vector<3xf32>>
    %result = spirv.Transpose %arg0 : !spirv.matrix<3 x vector<2xf32>> -> !spirv.matrix<2 x vector<3xf32>>
    spirv.ReturnValue %result : !spirv.matrix<2 x vector<3xf32>>
  }

  // CHECK-LABEL: @matrix_transpose_2
  spirv.func @matrix_transpose_2(%arg0 : !spirv.matrix<3 x vector<3xf32>>) -> !spirv.matrix<3 x vector<3xf32>> "None" {
    // CHECK: {{%.*}} = spirv.Transpose {{%.*}} : !spirv.matrix<3 x vector<3xf32>> -> !spirv.matrix<3 x vector<3xf32>>
    %result = spirv.Transpose %arg0 : !spirv.matrix<3 x vector<3xf32>> -> !spirv.matrix<3 x vector<3xf32>>
    spirv.ReturnValue %result : !spirv.matrix<3 x vector<3xf32>>
  }

  // CHECK-LABEL: @matrix_times_vector_1
  spirv.func @matrix_times_vector_1(%arg0: !spirv.matrix<3 x vector<4xf32>>, %arg1: vector<3xf32>) -> vector<4xf32> "None" {
    // CHECK: {{%.*}} = spirv.MatrixTimesVector {{%.*}}, {{%.*}} : !spirv.matrix<3 x vector<4xf32>>, vector<3xf32> -> vector<4xf32>
    %result = spirv.MatrixTimesVector %arg0, %arg1 : !spirv.matrix<3 x vector<4xf32>>, vector<3xf32> -> vector<4xf32>
    spirv.ReturnValue %result : vector<4xf32>
  }

  // CHECK-LABEL: @vector_times_matrix_1
  spirv.func @vector_times_matrix_1(%arg0: vector<3xf32>, %arg1: !spirv.matrix<4 x vector<3xf32>>) -> vector<4xf32> "None" {
    // CHECK: {{%.*}} = spirv.VectorTimesMatrix {{%.*}}, {{%.*}} : vector<3xf32>, !spirv.matrix<4 x vector<3xf32>> -> vector<4xf32>
    %result = spirv.VectorTimesMatrix %arg0, %arg1 : vector<3xf32>, !spirv.matrix<4 x vector<3xf32>> -> vector<4xf32>
    spirv.ReturnValue %result : vector<4xf32>
  }

  // CHECK-LABEL: @matrix_times_matrix_1
  spirv.func @matrix_times_matrix_1(%arg0: !spirv.matrix<3 x vector<3xf32>>, %arg1: !spirv.matrix<3 x vector<3xf32>>) -> !spirv.matrix<3 x vector<3xf32>> "None"{
    // CHECK: {{%.*}} = spirv.MatrixTimesMatrix {{%.*}}, {{%.*}} : !spirv.matrix<3 x vector<3xf32>>, !spirv.matrix<3 x vector<3xf32>> -> !spirv.matrix<3 x vector<3xf32>>
    %result = spirv.MatrixTimesMatrix %arg0, %arg1 : !spirv.matrix<3 x vector<3xf32>>, !spirv.matrix<3 x vector<3xf32>> -> !spirv.matrix<3 x vector<3xf32>>
    spirv.ReturnValue %result : !spirv.matrix<3 x vector<3xf32>>
  }

  // CHECK-LABEL: @matrix_times_matrix_2
  spirv.func @matrix_times_matrix_2(%arg0: !spirv.matrix<3 x vector<2xf32>>, %arg1: !spirv.matrix<2 x vector<3xf32>>) -> !spirv.matrix<2 x vector<2xf32>> "None"{
    // CHECK: {{%.*}} = spirv.MatrixTimesMatrix {{%.*}}, {{%.*}} : !spirv.matrix<3 x vector<2xf32>>, !spirv.matrix<2 x vector<3xf32>> -> !spirv.matrix<2 x vector<2xf32>>
    %result = spirv.MatrixTimesMatrix %arg0, %arg1 : !spirv.matrix<3 x vector<2xf32>>, !spirv.matrix<2 x vector<3xf32>> -> !spirv.matrix<2 x vector<2xf32>>
    spirv.ReturnValue %result : !spirv.matrix<2 x vector<2xf32>>
  }
}

// -----

func.func @input_type_mismatch(%arg0 : !spirv.matrix<3 x vector<3xf32>>, %arg1 : f16) {
  // expected-error @+1 {{input matrix components' type and scaling value must have the same type}}
  %result = spirv.MatrixTimesScalar %arg0, %arg1 : !spirv.matrix<3 x vector<3xf32>>, f16
  return
}

// -----

func.func @input_type_mismatch(%arg0 : !spirv.matrix<3 x vector<3xf32>>, %arg1 : f64) {
  // expected-error @+1 {{input matrix components' type and scaling value must have the same type}}
  %result = spirv.MatrixTimesScalar %arg0, %arg1 : !spirv.matrix<3 x vector<3xf32>>, f64
  return
}

// -----

func.func @transpose_op_shape_mismatch_1(%arg0 : !spirv.matrix<3 x vector<4xf32>>) {
   // expected-error @+1 {{input matrix rows count must be equal to output matrix columns count}}
   %result = spirv.Transpose %arg0 : !spirv.matrix<3 x vector<4xf32>> -> !spirv.matrix<3 x vector<3xf32>>
   return
}

// -----

func.func @transpose_op_shape_mismatch_2(%arg0 : !spirv.matrix<3 x vector<4xf32>>) {
   // expected-error @+1 {{input matrix rows count must be equal to output matrix columns count}}
   %result = spirv.Transpose %arg0 : !spirv.matrix<3 x vector<4xf32>> -> !spirv.matrix<2 x vector<4xf32>>
   return
}

// -----

func.func @transpose_op_type_mismatch(%arg0 : !spirv.matrix<3 x vector<4xf32>>) {
   // expected-error @+1 {{input and output matrices must have the same component type}}
   %result = spirv.Transpose %arg0 : !spirv.matrix<3 x vector<4xf32>> -> !spirv.matrix<4 x vector<3xf16>>
   return
}

// -----

func.func @matrix_times_matrix_invalid_input_shape_1(%arg0 : !spirv.matrix<3 x vector<2xf32>>, %arg1 : !spirv.matrix<2 x vector<3xf32>>){
   // expected-error @+1 {{right and result matrices must have equal columns' count}}
   %result = spirv.MatrixTimesMatrix %arg0, %arg1 : !spirv.matrix<3 x vector<2xf32>>, !spirv.matrix<2 x vector<3xf32>> -> !spirv.matrix<3 x vector<2xf32>>
   return
}

// -----

func.func @matrix_times_matrix_invalid_input_shape_2(%arg0 : !spirv.matrix<3 x vector<2xf32>>, %arg1 : !spirv.matrix<2 x vector<3xf32>>){
   // expected-error @+1 {{left and result matrices must have equal rows' count}}
   %result = spirv.MatrixTimesMatrix %arg0, %arg1 : !spirv.matrix<3 x vector<2xf32>>, !spirv.matrix<2 x vector<3xf32>> -> !spirv.matrix<2 x vector<3xf32>>
   return
}

// -----

func.func @matrix_times_matrix_inputs_shape_mismatch(%arg0 : !spirv.matrix<3 x vector<2xf32>>, %arg1 : !spirv.matrix<2 x vector<2xf32>>){
   // expected-error @+1 {{left matrix columns' count must be equal to the right matrix rows' count}}
   %result = spirv.MatrixTimesMatrix %arg0, %arg1 : !spirv.matrix<3 x vector<2xf32>>, !spirv.matrix<2 x vector<2xf32>> -> !spirv.matrix<2 x vector<2xf32>>
   return
}

// -----

func.func @matrix_times_matrix_component_type_mismatch_1(%arg0 : !spirv.matrix<3 x vector<3xf32>>, %arg1 : !spirv.matrix<3x vector<3xf32>>){
   // expected-error @+1 {{right and result matrices' component type must be the same}}
   %result = spirv.MatrixTimesMatrix %arg0, %arg1 : !spirv.matrix<3 x vector<3xf32>>, !spirv.matrix<3 x vector<3xf32>> -> !spirv.matrix<3 x vector<3xf64>>
   return
}

// -----

func.func @matrix_times_matrix_component_type_mismatch_2(%arg0 : !spirv.matrix<3 x vector<3xf64>>, %arg1 : !spirv.matrix<3x vector<3xf32>>){
   // expected-error @+1 {{left and result matrices' component type must be the same}}
   %result = spirv.MatrixTimesMatrix %arg0, %arg1 : !spirv.matrix<3 x vector<3xf64>>, !spirv.matrix<3 x vector<3xf32>> -> !spirv.matrix<3 x vector<3xf32>>
   return
}

// -----

func.func @matrix_times_vector_element_type_mismatch(%arg0: !spirv.matrix<4 x vector<3xf32>>, %arg1: vector<4xf16>) {
  // expected-error @+1 {{op failed to verify that all of {vector, result} have same element type}}
  %result = spirv.MatrixTimesVector %arg0, %arg1 : !spirv.matrix<4 x vector<3xf32>>, vector<4xf16> -> vector<3xf32>
  return
}

// -----

func.func @matrix_times_vector_row_mismatch(%arg0: !spirv.matrix<4 x vector<3xf32>>, %arg1: vector<4xf32>) {
  // expected-error @+1 {{spirv.MatrixTimesVector' op result size (4) must match the matrix rows (3)}}
  %result = spirv.MatrixTimesVector %arg0, %arg1 : !spirv.matrix<4 x vector<3xf32>>, vector<4xf32> -> vector<4xf32>
  return
}

// -----

func.func @matrix_times_vector_column_mismatch(%arg0: !spirv.matrix<4 x vector<3xf32>>, %arg1: vector<3xf32>) {
  // expected-error @+1 {{spirv.MatrixTimesVector' op matrix columns (4) must match vector operand size (3)}}
  %result = spirv.MatrixTimesVector %arg0, %arg1 : !spirv.matrix<4 x vector<3xf32>>, vector<3xf32> -> vector<3xf32>
  return
}

// -----

func.func @vector_times_matrix_vector_matrix_mismatch(%arg0: vector<4xf32>, %arg1: !spirv.matrix<4 x vector<3xf32>>) {
  // expected-error @+1 {{number of components in vector must equal the number of components in each column in matrix}}
  %result = spirv.VectorTimesMatrix %arg0, %arg1 : vector<4xf32>, !spirv.matrix<4 x vector<3xf32>> -> vector<3xf32>
  return
}

// -----

func.func @vector_times_matrix_result_matrix_mismatch(%arg0: vector<3xf32>, %arg1: !spirv.matrix<4 x vector<3xf32>>) {
  // expected-error @+1 {{number of columns in matrix must equal the number of components in result}}
  %result = spirv.VectorTimesMatrix %arg0, %arg1 : vector<3xf32>, !spirv.matrix<4 x vector<3xf32>> -> vector<3xf32>
  return
}

// -----

func.func @vector_times_matrix_vector_type_mismatch(%arg0: vector<3xf16>, %arg1: !spirv.matrix<4 x vector<3xf32>>) {
  // expected-error @+1 {{op failed to verify that all of {vector, result} have same element type}}
  %result = spirv.VectorTimesMatrix %arg0, %arg1 : vector<3xf16>, !spirv.matrix<4 x vector<3xf32>> -> vector<4xf32>
  return
}

// -----

func.func @vector_times_matrix_matrix_type_mismatch(%arg0: vector<3xf32>, %arg1: !spirv.matrix<4 x vector<3xf16>>) {
  // expected-error @+1 {{matrix must be a matrix with the same component type as the component type in result}}
  %result = spirv.VectorTimesMatrix %arg0, %arg1 : vector<3xf32>, !spirv.matrix<4 x vector<3xf16>> -> vector<4xf32>
  return
}

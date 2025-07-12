#include <pybind11/pybind11.h>
#include <torch/extension.h>
#include "utils.h"

// 前向声明
torch::Tensor trilinear_interpolation_fw(
    const torch::Tensor feats,
    const torch::Tensor points);

torch::Tensor trilinear_interpolation_bw(
    const torch::Tensor dL_dfeat_interp,
    const torch::Tensor feats,
    const torch::Tensor points);

PYBIND11_MODULE(cppcuda_tutorial, m)
{
    m.doc() = "Trilinear interpolation CUDA extension";

    m.def("trilinear_interpolation_fw", &trilinear_interpolation_fw,
          "Trilinear interpolation forward pass",
          pybind11::arg("feats"), pybind11::arg("points"));

    m.def("trilinear_interpolation_bw", &trilinear_interpolation_bw,
          "Trilinear interpolation backward pass",
          pybind11::arg("dL_dfeat_interp"), pybind11::arg("feats"), pybind11::arg("points"));
}
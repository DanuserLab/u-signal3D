# u-Signal3D

## User Guide to the u-Signal3D Software Package

![Alt Text](doc/FigUserGuide.png?raw=true)

### Publication

The mathematical approach of the u-signal3D package is described in this paper, [**Cellular harmonics for the morphology-invariant analysis of molecular organization at the cell surface**](https://doi.org/10.1038/s43588-023-00512-4), *Nature Computational Science*, 2023, written by Hanieh Mazloom-Farsibaf, Qiongjing Zou, Rebecca Hsieh, [Gaudenz Danuser](https://www.danuserlab-utsw.org/), Meghan Driscoll.


### Overview

The u-signal3D package is primarily designed to quantitatively analyze the spatial scales of molecular organization at 3D cell surface. We applied the Laplace-Beltrami operator (LBO) to a triangle mesh, represented the cell shape, to generate frequency-based hierarchical functions as a basis function, then decompose cell surface signaling across spatial scales created within this basis set. The u-signal3D framework is a series of MATLAB functions bundled into a user-friendly interface.

### Memory usage

To run the examples, we used a system with at least 32GB of RAM. The package can be downloaded and run easily on Windows and Linux. If a lower RAM is used, we recommend monitoring the memory usage. When computing the Laplacian, you can reduce the memory usage by choosing a lower number of eigenvectors ( < 500). This package can run in parallel mode if sufficient memory is available.

### Repository Structure

The u-signal3D package is based on an object-oriented framework developed and used in Gaudenz Danuser’s laboratory. Each data is associated with a MovieData object, which is used to link raw data with analysis outputs. The u-signal3D package includes six processes associated with MovieData objects. The processes are interdependent and run in serial (see example 1).

An alternative approach to the object-oriented format of the package is to use the basic functions associated with each process independently and save the results of each process in the local path. Functions that accumulate data from multiple cells, such as during validation, occur outside of the package framework.

The u-signal3D package accepts 3D images as input. Since the LBO generates the harmonic functions on a triangle mesh, the pipeline includes the cell surface segmentation functionality of an updated version of [u-shape3D](https://github.com/DanuserLab/u-shape3D), which generates surface meshes from 3D images. Users can also import mesh files directly in .obj or .ply format (see example 2). The output of the package is an “energy density spectra”, which describes the spatial scale of molecular organization at the cell surface. The Laplace-Beltrami operator is a scale invariant operator. Thus to measure actual spatial scales, the user needs to generate polka dot patterns on the same cell shape and compare the energy density spectra of the polka dots with the real signal on the same cell surface (see example 3). 

The package comprises the following processes,
1.	deconvolution – optionally deconvolves the movie 
2.	computeMIP -  optionally generates maximum intensity projections of the movie 
3.	mesh – creates a triangle mesh representing the cell surface 
4.	intensity - measures fluorescence intensity near the surface
5.	laplacian – computes the Laplace-Beltrami operator harmonic basis functions
6.	energy spectra - calculates the energy spectra of surface molecular organization


### Getting Started

1. 	Download the [code](https://github.com/DanuserLab/u-signal3D/tree/uSignal3Dpaper) and [example image](https://cloud.biohpc.swmed.edu/index.php/s/MfgQ23KWYED66iR/download). Set MATLAB’s path to include all the MATLAB functions provided by this package, using the “Set Path” button in MATLAB (Home > Environment > Set Path > Add with subfolders).

2. 	To generate polka dot pattern, some mex functions from the toolbox_fast_marching are needed. Before running the code, type these commands in the Command Window:(make sure the package is in MATLAB's current folder)

    a.	`cd u-signal3D-uSignal3Dpaper`

    b.	`cd extern`

    c.  `compile_mex`

    d. If done, this message will be shown in the Command Window “MEX completed successfully”

3. 	To run the Laplacian for non-manifold meshes (not necessary for provided examples),  the LBMode should set to‘tuftedMesh’. We wrote a function to use the [non-manifold Laplacian toolbox](https://github.com/nmwsharp/nonmanifold-laplacian). User needs to add the path of two executable files (tufted and tufted-idt) from the Laplace-Beltrami folder into the PATH environment variable of the current system. Please check [README](https://github.com/DanuserLab/u-signal3D/tree/uSignal3Dpaper/Laplace_Beltrami/README.md).

**Example 1: Spectral decomposition of a molecular signal at the cell surface from a 3D image using the u-signal3D package.**

This example shows how to apply the Laplace-Beltrami operator to a 3D image and generate the energy spectra of molecular fluorescence intensity near the cell membrane. 
1.	Open [*runUSignal3Dimage3D.m*](https://github.com/DanuserLab/u-signal3D/tree/uSignal3Dpaper/scripts/runUSignal3Dimage3D.m), the script that analyzes the PI3K-labeled cell (Example1), by typing `edit runUSignal3Dimage3D` in MATLAB’s command window.

2.	In the set directories section of the m-file, set the paths for

    a.	imageDirectory – the directory of the provided PI3K-labeled cell 

    b.	psfDirectory – the directory of the provided PSF

    c.	saveDirectory – the directory where output data will be saved

3.	Save the m-file and run it by typing `runUSignal3Dimage3D` in MATLAB’s command window. Note that a pool for parallel processing will likely open. You can control the parallel processing before running the m-file through MATLAB/home/Preferences/Parallel Computing Toolbox.

4. 	Users can change the parameters for each step (check runUSignal3Dimage3D.m).
 
Expected output is a folder created in saveDirectory, including a subfolder for each process. The package creates three figures, 1) mesh curvature at the cell surface, 2) intensity of the molecular pattern at the surface, 3) energy spectrum of the molecular pattern.
Running time on a system with 32 GB of RAM: ~ 5 minutes

**Example 2: Spectral decomposition of a molecular signal at the cell surface from a mesh provided as a .obj file.**

This example shows how to apply the Laplace-Beltrami operator to a 3D mesh and generate the energy spectra of molecular fluorescence intensity near the cell membrane (the 3D image is still required to measure the intensity on the mesh surface).
1.	Open [*runUSignal3DmeshSurface.m*](https://github.com/DanuserLab/u-signal3D/blob/uSignal3Dpaper/scripts/runUSignal3DmeshSurface.m), the script that analyzes the PI3K-labeled cell (Example2), by typing `edit runUSignal3DmeshSurface` in MATLAB’s command window.

2.	In the set directories section of the m-file, set the paths for

    a.	imageDirectory – the directory of the provided PI3K-labeled cell 

    b.	meshName – the name of the provided mesh (.obj or .ply file) in imageDirectory

    c.	saveDirectory – the directory where output data will be saved

3.	Save the m-file and run it by typing `runUSignal3DmeshSurface` in MATLAB’s command window. Note that a pool for parallel processing will likely open. You can control the parallel processing before running the m-file through MATLAB/home/Preferences/Parallel Computing Toolbox.

4. 	Users can change the parameters for each step (check runUSignal3DmeshSurface.m).
 
Expected output is a folder created in saveDirectory, including a subfolder for each process. The package creates three figures, 1) mesh curvature at the cell surface, 2) intensity of the molecular pattern at the surface, 3) energy spectrum of the molecular pattern.
Running time on a system with 32 GB of RAM: ~ 5 minutes

**Example 3: Generating polka dot patterns on a given cell surface.**
 
This example shows how to generate polka dot patterns on a given mesh. As described in the paper, we validated the pipeline by generating polka dot patterns on experimentally measured cell morphologies.
1.	Open [*runPolkaDotOnMesh.m*](https://github.com/DanuserLab/u-signal3D/tree/uSignal3Dpaper/scripts/runPolkaDotOnMesh.m), the script that analyzes the PI3K-labeled cell (Example3), by typing `edit runPolkaDotOnMesh` in MATLAB’s command window.

2.	In the set directories section of the m-file, set the paths for

    a.	meshDirectory – the directory of the provided triangle mesh surface.

    b.	saveDirectory – the directory where output will be saved.
  	
3.	Save the m-file and run it by typing `runPolkaDotOnMesh` in MATLAB’s command window. 

4. 	Users can change the parameters for generating polka dot pattern for example,

    a.	nDots – number of dots on the mesh surface.

    b.	areaDots – fraction of total surface area occupied by polka dots.

Expected output is a folder created in saveDirectory with a figure that visualizes the polka dot pattern on the cell surface, and .a mat file with the polka dot pattern as an intensity defined at mesh vertices.
Running time on a system with 32 GB of RAM: ~ 1 minutes

### Danuser Lab Links

[Danuser Lab Website](https://www.danuserlab-utsw.org/)

[Software Links](https://github.com/DanuserLab/)

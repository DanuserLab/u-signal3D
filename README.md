# u-signal3D

## User guide to the u-signal3D software package

**Publication**

The mathematical approach of the u-signal3D package is described in this paper, [***Cellular harmonics for the morphology-invariant analysis of molecular organization at the cell surface***](https://doi.org/10.1101/2022.08.17.504332), written by Hanieh Mazloom-Farsibaf, Qiongjing Zou, Rebecca Hsieh, [Gaudenz Danuser](https://www.danuserlab-utsw.org/), Meghan Driscoll (2022).


**Overview**

The u-signal3D package is primarily designed to quantitatively analyze the spatial scales of molecular organization at 3D cell surface. We applied the Laplace-Beltrami operator (LBO) to a triangle mesh, represented the cell shape, to generate frequency-based hierarchical functions as a basis function, then decompose cell surface signaling across spatial scales created within this basis set. The u-signal3D framework is a series of MATLAB functions bundled into a user-friendly interface.


**Architecture**

The u-signal3D package is based on an object-oriented framework used in Gaudenz Danuser’s laboratory packages. Each data is encapsulated as a MovieData object, containing the basic information of the raw image. Processes are associated with MovieData objects and are bundled into the u-signal3D package that track interdependencies between processes that run in serial. For convenience, package is associated with a user-friendly interference GUI. An alternative approach is to use the basic functions for each process independently and save the results of each process in the local path. Functions that accumulate data from multiple cells, such as validation and assessing similarity between spatial scale of signal distribution across cell morphologies, occur outside of the package framework.
The u-signal3D package accepts either 3D images or triangle meshes as input. Since the LBO generates the harmonic functions on a triangle mesh, the pipeline includes the cell surface segmentation functionality of updated version of u-shape3D, which generates surface meshes from 3D images[^1]. Therefore, users can skip the first four processes if a triangle mesh with associated local signal values (such as fluorescent molecular intensity) is used as an input. The energy density spectra describes the spatial scale of molecular organization at the cell surface.
The package comprises the following processes,
1.	deconvolution – optionally deconvolves the movie 
2.	computeMIP -  optionally generate the maximum intensity projections of the movie 
3.	mesh – creates a triangle mesh representing the cell surface 
4.	intensity - measures fluorescence intensity near the surface
5.	laplacian – computes the Laplace-Beltrami Operator harmonic basis functions
6.	energy spectra - calculates the energy spectra of surface molecular organization


**Example 1: Generating spectral decomposition of a molecular signal at the cell surface for a 3D image using the written script in the u-signal3D package.**

This example shows how to apply the Laplace-Beltrami operator to a 3D image and generate the energy spectra of molecular fluorescence intensity near the cell membrane. 
1.	Download the [code](https://github.com/DanuserLab/u-signal3D/tree/master/software) and [example image](https://cloud.biohpc.swmed.edu/index.php/s/6ZxQwsKk745Xf76/download). Set the MATLAB’s path for including all the MATLAB’s functions provided by this package, using the “Set Path” button in MATLAB. 
2.	Open [*runUSignal3Dimage3D.m*](https://github.com/DanuserLab/u-signal3D/blob/master/scripts/runUSignal3Dimage3D.m), the script that analyzes the PI3K-labeled cell, by typing `edit runUSignal3Dimage3D` in MATLAB’s command window.  
3.	In the set directories section of the m-file, set the paths for

    a.	imageDirectory – the directory of the provided PI3K-labeled cell.

    b.	psfDirectory – the directory for provided corresponding microscopy.

    c.	saveDirectory – the directory where output will be saved.

4.	Save the m-file and run it by typing `runUSignal3Dimage3D` in MATLAB’s command window. Note that a pool for parallel processing will likely open. You can control the parallel processing before running the m-file through MATLAB/home/Preferences/Parallel Computing Toolbox.

**Reference**

[^1]: Driscoll, M. K. et al. [Robust and automated detection of subcellular morphological motifs in 3D microscopy images](https://www.nature.com/articles/s41592-019-0539-z). *Nature Methods* 16, 1037-1044 (2019). 

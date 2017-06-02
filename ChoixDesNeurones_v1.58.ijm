/*This macro was created by Eric DENARIER  and  Benoit BOULAN 
on left click the selected neuron is cropped and skeletonized, the loops inside the skeleton are removed by suppressing the lowest intensity pixel on the corresponding original_neuron image.
output is stacks for different neurons :
skelet body  skelet+body  skelet-body  original_neuron  binary_neuron
parameters
line107 AND 145  body size= 28 
*/
////////////////////////////Body size ////////////////////////////////////////////

body=20

/////////////////////////////////////////////////////////////////////////////////////////////
showMessage("Choice of Neurons", "++++++++Welcome into AutoNeuriteJ !++++++++");
waitForUser("Open the original image");
open();
run("Set Scale...", "distance=1");
title2=getTitle();
run("8-bit");
waitForUser("Open the binarized image corresponding to the original");
open();
run("Set Scale...", "distance=1");
title=getTitle();

run("Options...", "iterations=1 count=1 black do=Nothing"); ////// I don't know what this is for....?
setOption("DisablePopupMenu", true);
//////////////////////////////////////Variable creation///////////////////////////////////////////////////////
i=0;
a=1;

coor_body=body/2
////////////////////////////////////Recording of neurons selections/////////////////////////////
showMessage("Select your Neurons : Left click on the cell body's center.\n \n Press Ctrl key if you want to remove a selection.\n \n Right click when you are done."); /////Instruction for the macro utilisation
        selectWindow(title2);
   		run("Select None");
		getCursorLoc(xCenter, yCenter, z, flags);
	
	if (flags==16 && IJ.getToolName()=="wand") {	
			
			selectWindow(title);
			makePoint(xCenter, yCenter);            /////we record both le localisation of the clic (in order to determine the center of the neuron body (in RoiManager)
			roiManager("Add");
			
			setTool("doWand");
			doWand(xCenter,yCenter);                /////we record the selection of the neuron borderlines (in RoiManager)  
		 	roiManager("Add");
				
			selectWindow(title2);
			run("Restore Selection");               /////Overlay creation on the image used to visualy select the neurons to quantify
			run("Add Selection...");
	} 
		 if (flags==2) {waitForUser("Wrong Selection? \n Delete it on RoiManager!");
		 if (flags==4) {selectWindow("MacroTxT"); run("Close");}

////////////////////////////////////////Constitution of Neuron images (Body-Skelet-BodySkelet-Original-Binarized)////////////////////////////////////////////////////
run("Remove Overlay");
waitForUser("RoiManager Check Up! \nClic Ok after deleting wrong selections");
roiManager("Deselect");
nROI=roiManager("count"); 
setBatchMode(true);
for(i=0;i<nROI;i=i+2){                         /////Loop for the creation of the vignets of each neurons

selectWindow(title2);
roiManager("Select", a);                       /////Select odds RoiManager selections
    getSelectionBounds(xSelec, ySelec, width, height);  /////recording of the neuron borderline coordinates
roiManager("Select", i);	                    /////Select pairs RoiManager selections
    getSelectionBounds(xPoint, yPoint, widthPoint, heightPoint);	/////recording of the neuron soma center coordinates	 		
				
				xNew=xPoint-xSelec+2;                           /////coordinates transfert for croped images of the neuron
				yNew=yPoint-ySelec+2;
////////////////////"Neuron original" images creation////////////////////
roiManager("Select", a);
run("Duplicate...", "title=Neuron_originale_"+xNew+"_"+yNew+"_"+i);
newwidth=width+2; newheight=height+2;
run("Canvas Size...", "width=&newwidth height=&newheight 220 position=Center zero");
////////////////////"Neuron binarized" images creation////////////////////
selectWindow(title);
roiManager("Select", a);
				run("Duplicate...", "title=Neuron_"+xNew+"_"+yNew+"_"+i);
				setBackgroundColor(0, 0, 0);
				run("Clear Outside");
				getDimensions(width, height, channels, slices, frames);
				newwidth=width+2; newheight=height+2;
				run("Canvas Size...", "width=&newwidth height=&newheight 220 position=Center zero");
				run("Duplicate...", "title=Skelet_"+xNew+"_"+yNew+"_"+i);
				run("Skeletonize", "stack");
////////////////////"Neuron skeleton with a body" images creation/////////			
				makeOval(xNew-coor_body, yNew-coor_body, body, body);                //////Diametre of the body fixed at 28pxls
				setForegroundColor(255, 255, 255);
				run("Fill", "slice");
				run("Select None");

//////////////////////////////Elimination of Loop inside the skeleton of the neuron /////////////////////////////////////////

selectWindow("BodSkele_"+xNew+"_"+yNew+"_"+i);
	run("Duplicate...", "title=[duplicatat]");             ////duplication of the original image to determine if a loop is found
selectWindow("BodSkele_"+xNew+"_"+yNew+"_"+i);
	run("Analyze Skeleton (2D/3D)", "prune=[lowest intensity branch] original_image=Neuron_originale_"+xNew+"_"+yNew+"_"+i); ////loop elimination (n.b. some times this function mis a loop when they are "concentric")

imageCalculator("Subtract create", "duplicatat","BodSkele_"+xNew+"_"+yNew+"_"+i);
selectWindow("Result of duplicatat");	
getStatistics(area, mean, min, max, std, histogram);

    while (mean!=0) {	                        //// We repeate the Skeleton Analysis if a loop is found
		selectWindow("Result of duplicatat");
		close();
		selectWindow("duplicatat");
		close();		
			selectWindow("BodSkele_"+xNew+"_"+yNew+"_"+i); ////duplication of the new original image to determine if a other loop can be find
			run("Duplicate...", "title=[duplicatat]");
			selectWindow("BodSkele_"+xNew+"_"+yNew+"_"+i);
			run("Analyze Skeleton (2D/3D)", "prune=[lowest intensity branch] original_image=Neuron_originale_"+xNew+"_"+yNew+"_"+i);
			imageCalculator("Subtract create", "duplicatat","BodSkele_"+xNew+"_"+yNew+"_"+i);
			selectWindow("Result of duplicatat");	
			getStatistics(area, mean, min, max, std, histogram);
	}
selectWindow("Result of duplicatat");
close();
selectWindow("duplicatat");
close();
//////////////////"Body" images creation//////////////////////////
			selectWindow("BodSkele_"+xNew+"_"+yNew+"_"+i);
			run("Select All");
			setForegroundColor(0, 0, 0);
			run("Fill", "slice");
			makeOval(xNew-coor_body, yNew-coor_body, body, body); 
			setForegroundColor(255, 255, 255);
			run("Fill", "slice");
			a=a+2;
}
 	selectWindow(title);   ////binary image closure
	close();
	selectWindow(title2);
	roiManager("Show All without labels");
	  
////////////////////////  Stack constitution (Body-Skelet-BodySkelet-NoBodySkelet-Original-Binarized) /////////////////////////////////////////////////////
run("Images to Stack", "method=[Copy (center)] name=Stack_Neuron_originale title=Neuron_originale use");
run("Images to Stack", "method=[Copy (center)] name=Stack_Neuron title=Neuron use");
run("Images to Stack", "method=[Copy (center)] name=Stack_Body title=Body use");
run("Multiply...", "value=255 stack"); ///// Why this fuc**** body has some time 248 value???? 
run("Images to Stack", "method=[Copy (center)] name=Stack_Skelet title=Skelet use");
run("Images to Stack", "method=[Copy (center)] name=Stack_BodySkelet title=BodSkele use");

/////////////////////// Closure of Skeleton analysis images produced//////////////////////////////////////////
run("Images to Stack", "method=[Copy (center)] name=Stack_tagged_skeleton title=Tagged skeleton use");	
////////////////// Saving and closure of stacks and ROI selections in a file nammed "resultat" created in the original image path////////////////
File.makeDirectory(sauvegarde+"/resultat_"+title3); 
run("BinaryConnectivity ", " ");
selectWindow("Stack_Body");
saveAs("tiff",sauvegarde+"/resultat_"+title3+"/Stack_Body"); close();

selectWindow("Stack_NoBodySkelet");
saveAs("tiff",sauvegarde+"/resultat_"+title3+"/Stack_NoBodySkelet"); close();

roiManager("Deselect");
roiManager("Save", sauvegarde+"/resultat_"+title3+"/RoiSet.zip"); close();

///This macro was created by Anne BEGHIN, Eric DENARIER and Benoit BOULAN
	

//////////////////////// Different measures : neurone cell body expansion /////////////////////////////////////////////////////
minAxon=80; // Minimal length to be an axon
minNeurite=10; // Minimal length to be a neurite
ratio=2; // Minimal ratio between (mean primary neurite length) and (axonal length)--> Requiered for the possible axon to be real one.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

defaultValue=1
z=0
w=0

////////////////////////////////////////Automate stack opening//////////////////////////////////////////
//////////NB: the file selected must contain any other folders than those who will be analysed (presence of other files isn't important)////

nombre_condition=getNumber("How many files to analyze?", defaultValue);   // Ask for the number of stack to be analysed
path=newArray(nombre_condition);
list=newArray(20)

for (z=0; z<nombre_condition; z++) {                                        // Ask for the directory of each stack to be analysed --> this correspond to the folder where the 1st macro create the saving folder.
	path[z] = getDirectory("Choose a Directory ");
}
	
		for (z=0; z<nombre_condition; z++) {                                // Automated opening of the stacks

			list = getFileList(path[z]);
					
			for (w=0; w<list.length; w++) {
			 
				if (endsWith(list[w], "/")) {                     //////////NB: the file selected must contain any other folders than those who will be analysed (presence of other files isn't important)////
				titre_culture=File.getName(list[w]);
				
				open(path[z] + list[w] + "/Stack_Body.tif");
				open(path[z] + list[w] + "/Stack_BodySkelet.tif");     
				open(path[z] + list[w] + "/Stack_NoBodySkelet.tif");
				open(path[z] + list[w] + "/Stack_Neuron_originale.tif");
				
selectImage("Stack_BodySkelet.tif");rename("Stack_BodySkelet");
selectImage("Stack_Body.tif");rename("Stack_Body");
selectWindow("Stack_NoBodySkelet.tif");rename("Stack_NoBodySkelet");
selectWindow("Stack_Neuron_originale.tif");rename("Stack_Neuron_originale");

setBackgroundColor(0, 0, 0);
setForegroundColor(255, 255, 255);
setBatchMode(true);
long_neurite=newArray(1000); type_neurite=newArray(1000);
nNeurones=nSlices;
neuroneArea =newArray(nSlices);
cellbodyArea = newArray(nSlices); 
expansionArea = newArray(nSlices);

//////////////////////////////// Stack name + axon determination conditions + Line of results titles////////////////////////////////////////////////////////////////
print(titre_culture);        
print("minAxon="+minAxon);
print("minNeurite="+minNeurite);
print("ratio="+ratio);	
print("Neurone \t Nb de primaires \t Ordre  \t Moyenne des Primaires \t Longueur Neurite \t Majeur \t Nb de primaires \t Axone_total \t Branchements axonaux");

////////////////////////////////  Loop for each neuron   /////////////////////////////////////////////////////////////////////////////

nb_neurones=nSlices;

for(j=1;j<=nb_neurones;j++){
					
		selectWindow("Stack_NoBodySkelet");	setSlice(j); run("Duplicate...", "title=masque_arbres"); // squelette des neurites séparés du noyau du Neurone n°j										
		selectWindow("Stack_BodySkelet"); setSlice(j); 	run("Duplicate...", "title=pointes"); run("Duplicate...", "title=S_et_S");
		selectWindow("Stack_Body");	setSlice(j);	run("Duplicate...", "title=CBS");		// Corps cellulaire neurone N° j									
		selectWindow("pointes"); 
		run("BinaryConnectivity ", "white");
		setThreshold(2, 2); run("Convert to Mask");			//	la valeur de connectivité 2 correspond aux extrémités
		run("Set Measurements...", "  bounding redirect=None decimal=3");
		run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display clear");
		Nb_pointes =nResults;
		
/////////////// Recherche pour chaque arbre de la plus longue branche sans passer par le ROI manager (trop lent)/////////////////////////////////////////
		
		grand_neurite = -1; neurite_majeur=-1;
			for(i=0;i<Nb_pointes;i++) 														// pour chaque extrémité :
				{	type_neurite[i]=2; 														// type neurite : 1 = axone, 2 = neurite (par défaut), 3... = branchement secondaire (ou plus) 
					selectWindow("S_et_S"); 
					nom="Neurone_"+j+"_Neurite"+i+1;	run("Duplicate...", "title="+nom); 	// Création d'une image par neurite
					x=getResult("BX", i); y=getResult("BY", i); 							// récupération du i_eme point 
					run ("Specify...", "width=2 height=2 x=" + x + " y=" + y + " centered"); // sélection d'une zone autour de l'extrémité
					setForegroundColor(255, 255, 255);                                      
					run("Fill", "slice"); 													// Remplissage de la zone sélectionnée, pavé sur une extrémité
					run("BinaryThin ", "kernel_a=[0 2 2 0 1 0 0 0 0 ] rotations=[rotate 45] iterations=-1 white"); //  ébarbulation (prune)
					imageCalculator("AND", nom,"masque_arbres");							// Affichage dans l'image neurone+branche ('= nom')
					doWand(x, y);run("Clear Outside");	run("Fill", "slice");	run("Skeletonize");			// nettoyage éventuel de  zones d'autres neurones
					doWand(x, y);getStatistics(area); 		grand=area; 					// = longueur depuis le noyau jusqu'à cette extrémité
					long_neurite[i]=grand;
						if(grand>=neurite_majeur) {neurite_majeur=grand;grand_neurite=i;	}	// Stockage de la plus grande longueur de neurite 
				}  

				
				//******************************** Recherche des neurites appariés ***********************************************
				//////////////// Comparaison entre Neurite i (jusqu'a Nb_Neurite-1)et neurite i+1 (jusqu'à Nbre Neurite)
				
				for(i=0;i<Nb_pointes-1;i++) 													// pour chaque neurite i
					{	x=getResult("BX", i); y=getResult("BY", i); 						// récupération de son extrémité  
						nom="Neurone_"+j+"_Neurite"+i+1;									// nom de l'image du neurite			
						for(k=i+1;k<Nb_pointes;k++) 										// pour chaque autre neurite
							{
								nom2="Neurone_"+j+"_Neurite"+k+1; selectWindow(nom2); run("Select None");	// image du second neurite et suppression de sélection
								selectWindow(nom);doWand(x, y, 0.0, "8-connected");			// selection de zone à partir de son extrémité x et y
								selectWindow(nom2);	run("Restore Selection");				// superposition du neurite i (sélection) dans l'image du neurite k 
									getStatistics(area, mean);overlap=mean;						// mesure de la zone de chevauchement des deux neurites par la moyenne de i contenant k
								if(overlap!=0) { 	
				
									if(long_neurite[i]>long_neurite[k]) 					// on rabote le neurite le plus petit, soit i, soit k (if... else...)
										{type_neurite[k]=type_neurite[k]+1;					// dégradation du neurite k vers un ordre plus élevé
										compareNeurite(nom2, nom);
										}
									
									else
										{type_neurite[i]=type_neurite[i]+1;					// dégradation du neurite i vers un ordre plus élevé
										compareNeurite (nom,nom2);
										} // end else
																												
									} // end if (overlap<255)
									
									//if  (overlap>=255) print ("neurites>255");  //overlap is > to 255 (I don't know why it is important !!!!!!!!!
															
									
							} // end for(k=i+1;k<Nb_pointes;k++)
					} // End neurites apparies

				//******************************** Synthèse par neurone et affichage des résultats *********************************************************
				
				LongPrim=0;	grand=newArray(200);	MoyPrim=0	; NbrPrim=0	;	NbrNeurite=0;				// pour calcul longueur moyenne des primaires
				for(i=0;i<Nb_pointes;i++) 													            // pour chaque neurite i
					{
					nom="Neurone_"+j+"_Neurite"+i+1;selectWindow(nom);
					x=getResult("BX", i); y=getResult("BY", i);doWand(x, y, 0.0, "8-connected");	
						getStatistics(area);grand[i]=area;	
						if(i != grand_neurite && area > minNeurite && type_neurite[i]==2)  {        
						                                    NbrPrim=NbrPrim+1;
															LongPrim=LongPrim+area; 						// somme des segments primaires sans le plus grand
					                                        MoyPrim=LongPrim/(NbrPrim);                   // Moyenne des segments primaires sans le plus grand
															}
					}
				

/////////////////////////////////////////Axon determination comparaison between potential axon and major primary dendrite /////////////////////////////////////////////////////////////////////////////////////				
								
if(neurite_majeur> minAxon) type_neurite[grand_neurite]=1;
grand_primaire=1;
		for(i=0;i<Nb_pointes;i++) {													// pour chaque neurite i
			if(grand_primaire <= grand[i] && grand[i]>minNeurite && type_neurite[i]==2 ){
			grand_primaire=grand[i];	
				if(neurite_majeur< ratio*grand_primaire){ 
				type_neurite[grand_neurite]=2;	
				}
			}
		}
if(type_neurite[grand_neurite]<=2){
	NbrPrim=NbrPrim+1;
	LongPrim=LongPrim+neurite_majeur;
	MoyPrim=LongPrim /(NbrPrim);
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
			//Ecriture sur tableau de résultats
			//print("Neurone \t Aire totale \t Aire soma \t Aire extensions \t Nb de Primaire \t  Neurite \t Ordre  \t Longueur \t Majeur");
			
				for(i=0;i<Nb_pointes;i++) 													// pour chaque neurite i
					{
					
					if(i != grand_neurite && grand[i]>minNeurite)
						print(j,"\t",NbrPrim, " \t ",type_neurite[i], "\t ",MoyPrim, "\t ", grand[i]);
			
					if(i == grand_neurite && grand[i]>minNeurite)
						print(j,"\t",NbrPrim, " \t ",type_neurite[i], "\t ",MoyPrim, "\t ", grand[i], "\t ", grand[i]);
					if(i==1) 
					print(j,"\t","\t","\t","\t","\t","\t",NbrPrim);
					}
										
					
				//*******************************************************************************************************************
				
			selectWindow("masque_arbres");close();
			selectWindow("S_et_S");close();
			selectWindow("pointes");close();
			selectWindow("CBS");close();
				
			for(i=0;i<Nb_pointes;i++) // pour chaque extrémité Donne la valeur de son type (type_neurite) au neurite
				{
					if (grand[i]<=minNeurite){									/// si le neurite n'est pas pris en compte car trop petit il sera supprimé du stack Neurone_use
					selectWindow("Neurone_"+j+"_Neurite"+i+1); close();
					} 
					
					else {
					selectWindow("Neurone_"+j+"_Neurite"+i+1);
					run("Select None");getStatistics(area, mean, min, max, std, histogram);
						if (mean!=0){
							setThreshold(255, 255);
							run("Create Selection");
							setForegroundColor(type_neurite[i], type_neurite[i], type_neurite[i]);
							run("Fill", "slice");
						} 
					run("Select None");
					}
				}
			
/////////////////////////////////////////Test de l'existence d'un stack (possible s'il n'y pas de dendrite reconnu)//////////////////////////
		o=0; axon_total=0;
		for(i=0;i<Nb_pointes;i++){
				test=isOpen("Neurone_"+j+"_Neurite"+i+1);
				if(test){o++;}
		}				
		if(o>=2){
			
			run("Images to Stack", "name=Neuron_"+j+" title=Neurone_ use"); // Stacks des neurites d'un neurone
			run("Z Project...", "projection=[Max Intensity]"); run("Duplicate...", "title=Axon_total");
run("8-bit");
run("Multiply...", "value=255");
x=getResult("BX", grand_neurite); y=getResult("BY", grand_neurite);doWand(x, y, 0.0, "8-connected");
run("Clear Outside");
getStatistics(area);
axon_total =area;

					selectWindow("Axon_total");
					run("BinaryConnectivity ", "white");
					setThreshold(2, 2); run("Convert to Mask");			//	la valeur de connectivité 2 correspond aux extrémités
					run("Set Measurements...", "  bounding redirect=None decimal=3");
					run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display clear");
					Nb_branchement =nResults-2;
					
if(type_neurite[grand_neurite]==1){
print(j,"\t","\t","\t","\t","\t","\t","\t",axon_total,"\t",Nb_branchement);}
selectWindow("Axon_total");close();	
			selectWindow("MAX_Neuron_"+j);
			run("Multiply...", "value=20");
			run("Rainbow RGB");
			selectWindow("Neuron_"+j);close();
		}	
			else{
				for(i=0;i<Nb_pointes;i++){
				test=isOpen("Neurone_"+j+"_Neurite"+i+1);
					if(test){
					selectWindow("Neurone_"+j+"_Neurite"+i+1);
					rename("MAX_Neuron_"+j);run("Duplicate...", "title=Axon_total");
					run("8-bit");
					run("Multiply...", "value=255");			
					x=getResult("BX", grand_neurite); y=getResult("BY", grand_neurite);doWand(x, y, 0.0, "8-connected");
					run("Clear Outside");
					getStatistics(area);
					axon_total =area;

//////////////////////////////////////nombre de branchement sur l'axon principal/////////////////////////////////
					selectWindow("Axon_total");
					run("BinaryConnectivity ", "white");
					setThreshold(2, 2); run("Convert to Mask");			//	la valeur de connectivité 2 correspond aux extrémités
					run("Set Measurements...", "  bounding redirect=None decimal=3");
					run("Analyze Particles...", "size=0-Infinity circularity=0.00-1.00 show=Nothing display clear");
					Nb_branchement =nResults-2;
		
					if(type_neurite[grand_neurite]==1){
					print(j,"\t","\t","\t","\t","\t","\t","\t",axon_total,"\t",Nb_branchement);}	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////		
					selectWindow("Axon_total");close();
					selectWindow("MAX_Neuron_"+j);
					run("Multiply...", "value=20");
					run("Rainbow RGB");
					}		
				}
			}	
	}  // Next Neuron

		
run("Images to Stack", "name=Stack_of_Neurones title=MAX use");
setBatchMode(false);
selectWindow("Stack_Body");close();
selectWindow("Stack_BodySkelet");close();
selectWindow("Stack_NoBodySkelet");close();
	
					
	File.makeDirectory(path[z] + list[w]+"/mesure_"+titre_culture);
	selectWindow("Log");
	saveAs("Text", path[z] + list[w]+"/mesure_"+titre_culture+"/Mesure_"+titre_culture);
	run("Close");
	
	
selectWindow("Stack_of_Neurones");
run("RGB Color");
selectWindow("Stack_Neuron_originale");
run("RGB Color");
imageCalculator("Transparent-zero create stack", "Stack_Neuron_originale","Stack_of_Neurones");
selectWindow("Result of Stack_Neuron_originale");
saveAs("tiff", path[z] + list[w]+"/mesure_"+titre_culture+"/Overlay_"+titre_culture);
selectWindow("Stack_of_Neurones");
saveAs("tiff", path[z] + list[w]+"/mesure_"+titre_culture+"/Stack_of_Neurones_"+titre_culture);
close(); close();close();

selectWindow("Results");
run("Close");
		}
     
  	 
	}

}
	
	
	
	
//////////////////////////////////////////////// Functions :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
	
	
	function getSummary(window,row, column) {//macro 3 et 4
selectWindow(window); lines = split(getInfo(), "\n");
	values = split(lines[row], "\t");

	if(column== 1){return values[0];}//Slice
	if(column== 2){return values[1];}//Count
	if(column== 3){return parseFloat(values[2]);}//Total Area
	if(column== 4){return values[3];}//Average Size
	if(column== 5){return values[4];}//Area Fraction
}

function compareNeurite(neurite1, neurite2)	{ //////////////// Si neurite 1 plus petit que 2
				
imageCalculator("Subtract create", neurite1,neurite2);
					selectWindow("Result of "+neurite1);
					run("Select All");
					run("Copy");
					selectWindow(neurite1);
					run("Paste");	
					run("Select None");
					selectWindow("Result of "+neurite1) ;close();
					}

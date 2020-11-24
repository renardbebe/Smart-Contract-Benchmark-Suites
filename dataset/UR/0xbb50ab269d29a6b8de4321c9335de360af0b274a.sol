 

pragma solidity 		^0.4.21	;							
												
		contract	Annexe_SO_DIVA_SAS		{							
												
			address	owner	;							
												
			function	Annexe_SO_DIVA_SAS		()	public	{				
				owner	= msg.sender;							
			}									
												
			modifier	onlyOwner	() {							
				require(msg.sender ==		owner	);					
				_;								
			}									
												
												
												
		 
												
												
			uint256	Titulaire_Compte_1	=	1000	;					
												
			function	setTitulaire_Compte_1	(	uint256	newTitulaire_Compte_1	)	public	onlyOwner	{	
				Titulaire_Compte_1	=	newTitulaire_Compte_1	;					
			}									
												
			function	getTitulaire_Compte_1	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_1	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_1	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_1	(	uint256	newAyantDroitEconomique_Compte_1	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_1	=	newAyantDroitEconomique_Compte_1	;					
			}									
												
			function	getAyantDroitEconomique_Compte_1	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_1	;						
			}									
												
												
												
		 
												
												
			uint256	Titulaire_Compte_2	=	1000	;					
												
			function	setTitulaire_Compte_2	(	uint256	newTitulaire_Compte_2	)	public	onlyOwner	{	
				Titulaire_Compte_2	=	newTitulaire_Compte_2	;					
			}									
												
			function	getTitulaire_Compte_2	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_2	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_2	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_2	(	uint256	newAyantDroitEconomique_Compte_2	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_2	=	newAyantDroitEconomique_Compte_2	;					
			}									
												
			function	getAyantDroitEconomique_Compte_2	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_2	;						
			}									
												
												
												
												
		 
												
												
			uint256	Titulaire_Compte_3	=	1000	;					
												
			function	setTitulaire_Compte_3	(	uint256	newTitulaire_Compte_3	)	public	onlyOwner	{	
				Titulaire_Compte_3	=	newTitulaire_Compte_3	;					
			}									
												
			function	getTitulaire_Compte_3	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_3	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_3	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_3	(	uint256	newAyantDroitEconomique_Compte_3	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_3	=	newAyantDroitEconomique_Compte_3	;					
			}									
												
			function	getAyantDroitEconomique_Compte_3	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_3	;						
			}									
												
												
												
		 
												
												
			uint256	Titulaire_Compte_4	=	1000	;					
												
			function	setTitulaire_Compte_4	(	uint256	newTitulaire_Compte_4	)	public	onlyOwner	{	
				Titulaire_Compte_4	=	newTitulaire_Compte_4	;					
			}									
												
			function	getTitulaire_Compte_4	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_4	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_4	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_4	(	uint256	newAyantDroitEconomique_Compte_4	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_4	=	newAyantDroitEconomique_Compte_4	;					
			}									
												
			function	getAyantDroitEconomique_Compte_4	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_4	;						
			}									
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
		 
												
												
			uint256	Titulaire_Compte_5	=	1000	;					
												
			function	setTitulaire_Compte_5	(	uint256	newTitulaire_Compte_5	)	public	onlyOwner	{	
				Titulaire_Compte_5	=	newTitulaire_Compte_5	;					
			}									
												
			function	getTitulaire_Compte_5	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_5	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_5	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_5	(	uint256	newAyantDroitEconomique_Compte_5	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_5	=	newAyantDroitEconomique_Compte_5	;					
			}									
												
			function	getAyantDroitEconomique_Compte_5	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_5	;						
			}									
												
												
												
		 
												
												
			uint256	Titulaire_Compte_6	=	1000	;					
												
			function	setTitulaire_Compte_6	(	uint256	newTitulaire_Compte_6	)	public	onlyOwner	{	
				Titulaire_Compte_6	=	newTitulaire_Compte_6	;					
			}									
												
			function	getTitulaire_Compte_6	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_6	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_6	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_6	(	uint256	newAyantDroitEconomique_Compte_6	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_6	=	newAyantDroitEconomique_Compte_6	;					
			}									
												
			function	getAyantDroitEconomique_Compte_6	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_6	;						
			}									
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
		 
												
												
			uint256	Titulaire_Compte_7	=	1000	;					
												
			function	setTitulaire_Compte_7	(	uint256	newTitulaire_Compte_7	)	public	onlyOwner	{	
				Titulaire_Compte_7	=	newTitulaire_Compte_7	;					
			}									
												
			function	getTitulaire_Compte_7	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_7	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_7	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_7	(	uint256	newAyantDroitEconomique_Compte_7	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_7	=	newAyantDroitEconomique_Compte_7	;					
			}									
												
			function	getAyantDroitEconomique_Compte_7	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_7	;						
			}									
												
												
												
		 
												
												
			uint256	Titulaire_Compte_8	=	1000	;					
												
			function	setTitulaire_Compte_8	(	uint256	newTitulaire_Compte_8	)	public	onlyOwner	{	
				Titulaire_Compte_8	=	newTitulaire_Compte_8	;					
			}									
												
			function	getTitulaire_Compte_8	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_8	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_8	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_8	(	uint256	newAyantDroitEconomique_Compte_8	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_8	=	newAyantDroitEconomique_Compte_8	;					
			}									
												
			function	getAyantDroitEconomique_Compte_8	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_8	;						
			}									
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
		 
												
												
			uint256	Titulaire_Compte_9	=	1000	;					
												
			function	setTitulaire_Compte_9	(	uint256	newTitulaire_Compte_9	)	public	onlyOwner	{	
				Titulaire_Compte_9	=	newTitulaire_Compte_9	;					
			}									
												
			function	getTitulaire_Compte_9	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_9	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_9	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_9	(	uint256	newAyantDroitEconomique_Compte_9	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_9	=	newAyantDroitEconomique_Compte_9	;					
			}									
												
			function	getAyantDroitEconomique_Compte_9	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_9	;						
			}									
												
												
												
		 
												
												
			uint256	Titulaire_Compte_10	=	1000	;					
												
			function	setTitulaire_Compte_10	(	uint256	newTitulaire_Compte_10	)	public	onlyOwner	{	
				Titulaire_Compte_10	=	newTitulaire_Compte_10	;					
			}									
												
			function	getTitulaire_Compte_10	()	public	constant	returns	(	uint256	)	{
				return	Titulaire_Compte_10	;						
			}									
												
												
												
		 
												
												
			uint256	AyantDroitEconomique_Compte_10	=	1000	;					
												
			function	setAyantDroitEconomique_Compte_10	(	uint256	newAyantDroitEconomique_Compte_10	)	public	onlyOwner	{	
				AyantDroitEconomique_Compte_10	=	newAyantDroitEconomique_Compte_10	;					
			}									
												
			function	getAyantDroitEconomique_Compte_10	()	public	constant	returns	(	uint256	)	{
				return	AyantDroitEconomique_Compte_10	;						
			}									
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
												
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


        }
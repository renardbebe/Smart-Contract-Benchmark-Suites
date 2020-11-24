 

pragma solidity ^0.4.24;							 
	 																																
	interface IERC20Token {																																
	      function totalSupply() public constant returns (uint);         																																
	      function balanceOf(address tokenlender) public constant returns (uint balance);         																																
	      function allowance(address tokenlender, address spender) public constant returns (uint remaining);         																																
	      function transfer(address to, uint tokens) public returns (bool success);         																																
	      function approve(address spender, uint tokens) public returns (bool success);         																																
	      function transferFrom(address from, address to, uint tokens) public returns (bool success);         																																
	 
	      event Transfer(address indexed from, address indexed to, uint tokens);         																																
	      event Approval(address indexed tokenlender, address indexed spender, uint tokens);																																
	}																																
	 																																
	contract			LifeSet_008			{	 
	 
	 
					 
																																	
					address	owner	;																										
																																	
					function	detOwner		() 	public	{																							
						owner	=	0x694f59266d12e339047353a170e21233806ab900								;					
					}																												
																																	
					modifier	onlyOwner		() 		{																							
						require(msg.sender == owner )										;																	
						_;																											
					}																												
	 																																
					uint256		public		consecutiveDeaths												;												
					uint256		public		lastHash												;												
																																	
		 
					uint256		public		deathData_v1												;												
					bool		public		CLE_Beta_Pictoris												;												
																																	
					address		public		User_1		=	msg.sender									;												
					uint256		public		Standard_1		=	100000000000000000000 ;																					
	 																																
	 																																
					 
	 
	 		uint256	public	DeathFactor_i					;																					
	 		uint256	public	DeathFactor_ii					;																					
	 		uint256	public	DeathFactor_iii					;																					
	 		uint256	public	DeathFactor_iv					;																					
	 		uint256	public	DeathFactor_v					;																					
	 		uint256	public	LifeFactor_i					;																					
	 		uint256	public	LifeFactor_ii					;																					
	 		uint256	public	LifeFactor_iii					;																					
	 		uint256	public	LifeFactor_iv					;																					
	 		uint256	public	LifeFactor_v					;																					
	 		uint256	public	lastBlock_f0					;																					
	 		uint256	public	lastBlock_f1					;																					
	 		uint256	public	lastBlock_f2					;																					
	 		uint256	public	lastBlock_f3					;																					
	 		uint256	public	lastBlock_f4					;																					
	 		uint256	public	lastBlock_f5					;																					
	 		uint256	public	lastBlock_f6					;																					
	 		uint256	public	lastBlock_f7					;																					
	 		uint256	public	lastBlock_f8					;																					
	 		uint256	public	lastBlock_f9					;																					
	 		uint256	public	lastBlock_f10					;																					
	 		uint256	public	lastBlock_f11					;																					
	 		uint256	public	lastBlock_f12					;																					
	 		uint256	public	lastBlock_f13					;																					
	 		uint256	public	lastBlock_f14					;																					
	 		uint256	public	lastBlock_f15					;																					
	 		uint256	public	lastBlock_f16					;																					
	 		uint256	public	lastBlock_f17					;																					
	 		uint256	public	lastBlock_f18					;																					
	 		uint256	public	lastBlock_f19					;																					
	 		uint256	public	lastBlock_f0Hash_uint256					;																					
	 		uint256	public	lastBlock_f1Hash_uint256					;																					
	 		uint256	public	lastBlock_f2Hash_uint256					;																					
	 		uint256	public	lastBlock_f3Hash_uint256					;																					
	 		uint256	public	lastBlock_f4Hash_uint256					;																					
	 		uint256	public	lastBlock_f5Hash_uint256					;																					
	 		uint256	public	lastBlock_f6Hash_uint256					;																					
	 		uint256	public	lastBlock_f7Hash_uint256					;																					
	 		uint256	public	lastBlock_f8Hash_uint256					;																					
	 		uint256	public	lastBlock_f9Hash_uint256					;																					
	 		uint256	public	lastBlock_f10Hash_uint256					;																					
	 		uint256	public	lastBlock_f11Hash_uint256					;																					
	 		uint256	public	lastBlock_f12Hash_uint256					;																					
	 		uint256	public	lastBlock_f13Hash_uint256					;																					
	 		uint256	public	lastBlock_f14Hash_uint256					;																					
	 		uint256	public	lastBlock_f15Hash_uint256					;																					
	 		uint256	public	lastBlock_f16Hash_uint256					;																					
	 		uint256	public	lastBlock_f17Hash_uint256					;																					
	 		uint256	public	lastBlock_f18Hash_uint256					;																					
	 		uint256	public	lastBlock_f19Hash_uint256					;																					
	 		uint256	public	deathData_f0					;																					
	 		uint256	public	deathData_f1					;																					
	 		uint256	public	deathData_f2					;																					
	 		uint256	public	deathData_f3					;																					
	 		uint256	public	deathData_f4					;																					
	 		uint256	public	deathData_f5					;																					
	 		uint256	public	deathData_f6					;																					
	 		uint256	public	deathData_f7					;																					
	 		uint256	public	deathData_f8					;																					
	 		uint256	public	deathData_f9					;																					
	 		uint256	public	deathData_f10					;																					
	 		uint256	public	deathData_f11					;																					
	 		uint256	public	deathData_f12					;																					
	 		uint256	public	deathData_f13					;																					
	 		uint256	public	deathData_f14					;																					
	 		uint256	public	deathData_f15					;																					
	 		uint256	public	deathData_f16					;																					
	 		uint256	public	deathData_f17					;																					
	 		uint256	public	deathData_f18					;																					
	 		uint256	public	deathData_f19					;																					
	 																																
					 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 		uint256	public	lastBlock_v0					;																					
	 		uint256	public	lastBlock_v1					;																					
	 		uint256	public	lastBlock_v2					;																					
	 		uint256	public	lastBlock_v3					;																					
	 		uint256	public	lastBlock_v4					;																					
	 		uint256	public	lastBlock_v5					;																					
	 		uint256	public	lastBlock_v6					;																					
	 		uint256	public	lastBlock_v7					;																					
	 		uint256	public	lastBlock_v8					;																					
	 		uint256	public	lastBlock_v9					;																					
	 		uint256	public	lastBlock_v10					;																					
	 		uint256	public	lastBlock_v11					;																					
	 		uint256	public	lastBlock_v12					;																					
	 		uint256	public	lastBlock_v13					;																					
	 		uint256	public	lastBlock_v14					;																					
	 		uint256	public	lastBlock_v15					;																					
	 		uint256	public	lastBlock_v16					;																					
	 		uint256	public	lastBlock_v17					;																					
	 		uint256	public	lastBlock_v18					;																					
	 		uint256	public	lastBlock_v19					;																					
	 		uint256	public	lastBlock_v0Hash_uint256					;																					
	 		uint256	public	lastBlock_v1Hash_uint256					;																					
	 		uint256	public	lastBlock_v2Hash_uint256					;																					
	 		uint256	public	lastBlock_v3Hash_uint256					;																					
	 		uint256	public	lastBlock_v4Hash_uint256					;																					
	 		uint256	public	lastBlock_v5Hash_uint256					;																					
	 		uint256	public	lastBlock_v6Hash_uint256					;																					
	 		uint256	public	lastBlock_v7Hash_uint256					;																					
	 		uint256	public	lastBlock_v8Hash_uint256					;																					
	 		uint256	public	lastBlock_v9Hash_uint256					;																					
	 		uint256	public	lastBlock_v10Hash_uint256					;																					
	 		uint256	public	lastBlock_v11Hash_uint256					;																					
	 		uint256	public	lastBlock_v12Hash_uint256					;																					
	 		uint256	public	lastBlock_v13Hash_uint256					;																					
	 		uint256	public	lastBlock_v14Hash_uint256					;																					
	 		uint256	public	lastBlock_v15Hash_uint256					;																					
	 		uint256	public	lastBlock_v16Hash_uint256					;																					
	 		uint256	public	lastBlock_v17Hash_uint256					;																					
	 		uint256	public	lastBlock_v18Hash_uint256					;																					
	 		uint256	public	lastBlock_v19Hash_uint256					;																					
	 		uint256	public	deathData_v0					;																					
	 
	 		uint256	public	deathData_v2					;																					
	 		uint256	public	deathData_v3					;																					
	 		uint256	public	deathData_v4					;																					
	 		uint256	public	deathData_v5					;																					
	 		uint256	public	deathData_v6					;																					
	 		uint256	public	deathData_v7					;																					
	 		uint256	public	deathData_v8					;																					
	 		uint256	public	deathData_v9					;																					
	 		uint256	public	deathData_v10					;																					
	 		uint256	public	deathData_v11					;																					
	 		uint256	public	deathData_v12					;																					
	 		uint256	public	deathData_v13					;																					
	 		uint256	public	deathData_v14					;																					
	 		uint256	public	deathData_v15					;																					
	 		uint256	public	deathData_v16					;																					
	 		uint256	public	deathData_v17					;																					
	 		uint256	public	deathData_v18					;																					
	 		uint256	public	deathData_v19					;																					
	 																																
					 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 		uint256	public	lastBlock_a0					;																					
	 		uint256	public	lastBlock_a1					;																					
	 		uint256	public	lastBlock_a2					;																					
	 		uint256	public	lastBlock_a3					;																					
	 		uint256	public	lastBlock_a4					;																					
	 		uint256	public	lastBlock_a5					;																					
	 		uint256	public	lastBlock_a6					;																					
	 		uint256	public	lastBlock_a7					;																					
	 		uint256	public	lastBlock_a8					;																					
	 		uint256	public	lastBlock_a9					;																					
	 		uint256	public	lastBlock_a10					;																					
	 		uint256	public	lastBlock_a11					;																					
	 		uint256	public	lastBlock_a12					;																					
	 		uint256	public	lastBlock_a13					;																					
	 		uint256	public	lastBlock_a14					;																					
	 		uint256	public	lastBlock_a15					;																					
	 		uint256	public	lastBlock_a16					;																					
	 		uint256	public	lastBlock_a17					;																					
	 		uint256	public	lastBlock_a18					;																					
	 		uint256	public	lastBlock_a19					;																					
	 		uint256	public	lastBlock_a0Hash_uint256					;																					
	 		uint256	public	lastBlock_a1Hash_uint256					;																					
	 		uint256	public	lastBlock_a2Hash_uint256					;																					
	 		uint256	public	lastBlock_a3Hash_uint256					;																					
	 		uint256	public	lastBlock_a4Hash_uint256					;																					
	 		uint256	public	lastBlock_a5Hash_uint256					;																					
	 		uint256	public	lastBlock_a6Hash_uint256					;																					
	 		uint256	public	lastBlock_a7Hash_uint256					;																					
	 		uint256	public	lastBlock_a8Hash_uint256					;																					
	 		uint256	public	lastBlock_a9Hash_uint256					;																					
	 		uint256	public	lastBlock_a10Hash_uint256					;																					
	 		uint256	public	lastBlock_a11Hash_uint256					;																					
	 		uint256	public	lastBlock_a12Hash_uint256					;																					
	 		uint256	public	lastBlock_a13Hash_uint256					;																					
	 		uint256	public	lastBlock_a14Hash_uint256					;																					
	 		uint256	public	lastBlock_a15Hash_uint256					;																					
	 		uint256	public	lastBlock_a16Hash_uint256					;																					
	 		uint256	public	lastBlock_a17Hash_uint256					;																					
	 		uint256	public	lastBlock_a18Hash_uint256					;																					
	 		uint256	public	lastBlock_a19Hash_uint256					;																					
	 		uint256	public	deathData_a0					;																					
	 		uint256	public	deathData_a1					;																					
	 		uint256	public	deathData_a2					;																					
	 		uint256	public	deathData_a3					;																					
	 		uint256	public	deathData_a4					;																					
	 		uint256	public	deathData_a5					;																					
	 		uint256	public	deathData_a6					;																					
	 		uint256	public	deathData_a7					;																					
	 		uint256	public	deathData_a8					;																					
	 		uint256	public	deathData_a9					;																					
	 		uint256	public	deathData_a10					;																					
	 		uint256	public	deathData_a11					;																					
	 		uint256	public	deathData_a12					;																					
	 		uint256	public	deathData_a13					;																					
	 		uint256	public	deathData_a14					;																					
	 		uint256	public	deathData_a15					;																					
	 		uint256	public	deathData_a16					;																					
	 		uint256	public	deathData_a17					;																					
	 		uint256	public	deathData_a18					;																					
	 		uint256	public	deathData_a19					;																					
	 																																
					 
	 
					function	LifeSet_008		() 	public	{	 
	 			DeathFactor_i	=	57896044618658097711785492504343953926634992332820282019728792003956564819968		;					
	 			DeathFactor_ii					=	21807848692836600000000000000										;					
	 			DeathFactor_iii					=	21079851993102300000000000000										;					
	 			DeathFactor_iv					=	96991823642008000000000000000										;					
	 			DeathFactor_v					=	23715149500320100000000000000										;					
	 			LifeFactor_i					=	72342521561722900000000000000										;					
	 			LifeFactor_ii					=	28761789998958900000000000000										;					
	 			LifeFactor_iii					=	49073762341743800000000000000										;					
	 			LifeFactor_iv					=	69895676296429600000000000000										;					
	 			LifeFactor_v					=	36799331971979100000000000000										;					
	 			lastBlock_f0					=	(block.number)										;											
	 			lastBlock_f1					=	(block.number-1)										;											
	 			lastBlock_f2					=	(block.number-2)										;											
	 			lastBlock_f3					=	(block.number-3)										;											
	 			lastBlock_f4					=	(block.number-4)										;											
	 			lastBlock_f5					=	(block.number-5)										;											
	 			lastBlock_f6					=	(block.number-6)										;											
	 			lastBlock_f7					=	(block.number-7)										;											
	 			lastBlock_f8					=	(block.number-8)										;											
	 			lastBlock_f9					=	(block.number-9)										;											
	 			lastBlock_f10					=	(block.number-10)										;											
	 			lastBlock_f11					=	(block.number-11)										;											
	 			lastBlock_f12					=	(block.number-12)										;											
	 			lastBlock_f13					=	(block.number-13)										;											
	 			lastBlock_f14					=	(block.number-14)										;											
	 			lastBlock_f15					=	(block.number-15)										;											
	 			lastBlock_f16					=	(block.number-16)										;											
	 			lastBlock_f17					=	(block.number-17)										;											
	 			lastBlock_f18					=	(block.number-18)										;											
	 			lastBlock_f19					=	(block.number-19)										;											
	 			lastBlock_f0Hash_uint256					=	uint256(block.blockhash(block.number))								;											
	 			lastBlock_f1Hash_uint256					=	uint256(block.blockhash(block.number-1))								;											
	 			lastBlock_f2Hash_uint256					=	uint256(block.blockhash(block.number-2))								;											
	 			lastBlock_f3Hash_uint256					=	uint256(block.blockhash(block.number-3))								;											
	 			lastBlock_f4Hash_uint256					=	uint256(block.blockhash(block.number-4))								;											
	 			lastBlock_f5Hash_uint256					=	uint256(block.blockhash(block.number-5))								;											
	 			lastBlock_f6Hash_uint256					=	uint256(block.blockhash(block.number-6))								;											
	 			lastBlock_f7Hash_uint256					=	uint256(block.blockhash(block.number-7))								;											
	 			lastBlock_f8Hash_uint256					=	uint256(block.blockhash(block.number-8))								;											
	 			lastBlock_f9Hash_uint256					=	uint256(block.blockhash(block.number-9))								;											
	 			lastBlock_f10Hash_uint256					=	uint256(block.blockhash(block.number-10))						;											
	 			lastBlock_f11Hash_uint256					=	uint256(block.blockhash(block.number-11))							;											
	 			lastBlock_f12Hash_uint256					=	uint256(block.blockhash(block.number-12))							;											
	 			lastBlock_f13Hash_uint256					=	uint256(block.blockhash(block.number-13))							;											
	 			lastBlock_f14Hash_uint256					=	uint256(block.blockhash(block.number-14))							;											
	 			lastBlock_f15Hash_uint256					=	uint256(block.blockhash(block.number-15))							;											
	 			lastBlock_f16Hash_uint256					=	uint256(block.blockhash(block.number-16))							;											
	 			lastBlock_f17Hash_uint256					=	uint256(block.blockhash(block.number-17))							;											
	 			lastBlock_f18Hash_uint256					=	uint256(block.blockhash(block.number-18))							;											
	 			lastBlock_f19Hash_uint256					=	uint256(block.blockhash(block.number-19))							;											
	 			deathData_f0					=	uint256(block.blockhash(block.number)) / DeathFactor_i							;											
	 			deathData_f1					=	uint256(block.blockhash(block.number-1)) / DeathFactor_i							;											
	 			deathData_f2					=	uint256(block.blockhash(block.number-2)) / DeathFactor_i							;											
	 			deathData_f3					=	uint256(block.blockhash(block.number-3)) / DeathFactor_i							;											
	 			deathData_f4					=	uint256(block.blockhash(block.number-4)) / DeathFactor_i							;											
	 			deathData_f5					=	uint256(block.blockhash(block.number-5)) / DeathFactor_i							;											
	 			deathData_f6					=	uint256(block.blockhash(block.number-6)) / DeathFactor_i							;											
	 			deathData_f7					=	uint256(block.blockhash(block.number-7)) / DeathFactor_i							;											
	 			deathData_f8					=	uint256(block.blockhash(block.number-8)) / DeathFactor_i							;											
	 			deathData_f9					=	uint256(block.blockhash(block.number-9)) / DeathFactor_i							;											
	 			deathData_f10					=	uint256(block.blockhash(block.number-10)) / DeathFactor_i					;											
	 			deathData_f11					=	uint256(block.blockhash(block.number-11)) / DeathFactor_i						;											
	 			deathData_f12					=	uint256(block.blockhash(block.number-12)) / DeathFactor_i						;											
	 			deathData_f13					=	uint256(block.blockhash(block.number-13)) / DeathFactor_i						;											
	 			deathData_f14					=	uint256(block.blockhash(block.number-14)) / DeathFactor_i						;											
	 			deathData_f15					=	uint256(block.blockhash(block.number-15)) / DeathFactor_i						;											
	 			deathData_f16					=	uint256(block.blockhash(block.number-16)) / DeathFactor_i						;											
	 			deathData_f17					=	uint256(block.blockhash(block.number-17)) / DeathFactor_i						;											
	 			deathData_f18					=	uint256(block.blockhash(block.number-18)) / DeathFactor_i						;											
	 			deathData_f19					=	uint256(block.blockhash(block.number-19)) / DeathFactor_i						;											
					}																										
	 																																
						 
	 
	 
	 			address 	public	User_2		;	 
	 			address 	public	User_3		;	 
	 			address 	public	User_4		;	 
	 			address 	public	User_5		;	 
	 
	 			IERC20Token		public	Securities_1		;	 
	 			IERC20Token		public	Securities_2		;	 
	 			IERC20Token		public	Securities_3		;	 
	 			IERC20Token		public	Securities_4		;	 
	 			IERC20Token		public	Securities_5		;	 
	 
	 
	 			uint256		public	Standard_2		;	 
	 			uint256		public	Standard_3		;	 
	 			uint256		public	Standard_4		;	 
	 			uint256		public	Standard_5		;	 
	 																																
						 
	 
	 			function	Eligibility_Group_1					( 																					
	 				address		_User_1		,																						
	 				IERC20Token		_Securities_1		,																						
	 				uint256		_Standard_1																								
	 			)																											
	 				public		onlyOwner																								
	 			{																											
	 
	 				Securities_1		=	_Securities_1		;																					
	 
	 			}																											
	 			function	Eligibility_Group_2					( 																					
	 				address		_User_2		,																						
	 				IERC20Token		_Securities_2		,																						
	 				uint256		_Standard_2																								
	 			)																											
	 				public		onlyOwner																								
	 			{																											
	 				User_2		=	_User_2		;																					
	 				Securities_2		=	_Securities_2		;																					
	 				Standard_2		=	_Standard_2		;																					
	 			}																											
	 			function	Eligibility_Group_3					( 																					
	 				address		_User_3		,																						
	 				IERC20Token		_Securities_3		,																						
	 				uint256		_Standard_3																								
	 			)																											
	 				public		onlyOwner																								
	 			{																											
	 				User_3		=	_User_3		;																					
	 				Securities_3		=	_Securities_3		;																					
	 				Standard_3		=	_Standard_3		;																					
	 			}																											
	 			function	Eligibility_Group_4					( 																					
	 				address		_User_4		,																						
	 				IERC20Token		_Securities_4		,																						
	 				uint256		_Standard_4																								
	 			)																											
	 				public		onlyOwner																								
	 			{																											
	 				User_4		=	_User_4		;																					
	 				Securities_4		=	_Securities_4		;																					
	 				Standard_4		=	_Standard_4		;																					
	 			}																											
	 			function	Eligibility_Group_5					( 																					
	 				address		_User_5		,																						
	 				IERC20Token		_Securities_5		,																						
	 				uint256		_Standard_5																								
	 			)																											
	 				public		onlyOwner																								
	 			{																											
	 				User_5		=	_User_5		;																					
	 				Securities_5		=	_Securities_5		;																					
	 				Standard_5		=	_Standard_5		;																					
	 			}																											
	 																																
						 
	 
function	ReinsureSeveralDeaths	(bool _hedge		) public returns ( bool	) {						
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 
	 				lastBlock_v0					=	(block.number)										;										
	 				lastBlock_v1					=	(block.number-1)										;										
	 				lastBlock_v2					=	(block.number-2)										;										
	 				lastBlock_v3					=	(block.number-3)										;										
	 				lastBlock_v4					=	(block.number-4)										;										
	 				lastBlock_v5					=	(block.number-5)										;										
	 				lastBlock_v6					=	(block.number-6)										;										
	 				lastBlock_v7					=	(block.number-7)										;										
	 				lastBlock_v8					=	(block.number-8)										;										
	 				lastBlock_v9					=	(block.number-9)										;										
	 				lastBlock_v10					=	(block.number-10)										;										
	 				lastBlock_v11					=	(block.number-11)										;										
	 				lastBlock_v12					=	(block.number-12)										;										
	 				lastBlock_v13					=	(block.number-13)										;										
	 				lastBlock_v14					=	(block.number-14)										;										
	 				lastBlock_v15					=	(block.number-15)										;										
	 				lastBlock_v16					=	(block.number-16)										;										
	 				lastBlock_v17					=	(block.number-17)										;										
	 				lastBlock_v18					=	(block.number-18)										;										
	 				lastBlock_v19					=	(block.number-19)										;										
	 				lastBlock_v0Hash_uint256					=	uint256(block.blockhash(block.number))							;										
	 
	 				lastBlock_v2Hash_uint256					=	uint256(block.blockhash(block.number-2))							;										
	 				lastBlock_v3Hash_uint256					=	uint256(block.blockhash(block.number-3))							;										
	 				lastBlock_v4Hash_uint256					=	uint256(block.blockhash(block.number-4))							;										
	 				lastBlock_v5Hash_uint256					=	uint256(block.blockhash(block.number-5))							;										
	 				lastBlock_v6Hash_uint256					=	uint256(block.blockhash(block.number-6))							;										
	 				lastBlock_v7Hash_uint256					=	uint256(block.blockhash(block.number-7))							;										
	 				lastBlock_v8Hash_uint256					=	uint256(block.blockhash(block.number-8))							;										
	 				lastBlock_v9Hash_uint256					=	uint256(block.blockhash(block.number-9))							;										
	 				lastBlock_v10Hash_uint256					=	uint256(block.blockhash(block.number-10))						;										
	 				lastBlock_v11Hash_uint256					=	uint256(block.blockhash(block.number-11))						;										
	 				lastBlock_v12Hash_uint256					=	uint256(block.blockhash(block.number-12))						;										
	 				lastBlock_v13Hash_uint256					=	uint256(block.blockhash(block.number-13))						;										
	 				lastBlock_v14Hash_uint256					=	uint256(block.blockhash(block.number-14))						;										
	 				lastBlock_v15Hash_uint256					=	uint256(block.blockhash(block.number-15))						;										
	 				lastBlock_v16Hash_uint256					=	uint256(block.blockhash(block.number-16))						;										
	 				lastBlock_v17Hash_uint256					=	uint256(block.blockhash(block.number-17))						;										
	 				lastBlock_v18Hash_uint256					=	uint256(block.blockhash(block.number-18))						;										
	 				lastBlock_v19Hash_uint256					=	uint256(block.blockhash(block.number-19))						;										
	 				deathData_v0					=	uint256(block.blockhash(block.number)) / DeathFactor_i						;										
	 				deathData_v1					=	uint256(block.blockhash(block.number-1)) / DeathFactor_i						;										
	 				deathData_v2					=	uint256(block.blockhash(block.number-2)) / DeathFactor_i						;										
	 				deathData_v3					=	uint256(block.blockhash(block.number-3)) / DeathFactor_i						;										
	 				deathData_v4					=	uint256(block.blockhash(block.number-4)) / DeathFactor_i						;										
	 				deathData_v5					=	uint256(block.blockhash(block.number-5)) / DeathFactor_i						;										
	 				deathData_v6					=	uint256(block.blockhash(block.number-6)) / DeathFactor_i						;										
	 				deathData_v7					=	uint256(block.blockhash(block.number-7)) / DeathFactor_i						;										
	 				deathData_v8					=	uint256(block.blockhash(block.number-8)) / DeathFactor_i						;										
	 				deathData_v9					=	uint256(block.blockhash(block.number-9)) / DeathFactor_i						;										
	 				deathData_v10					=	uint256(block.blockhash(block.number-10)) / DeathFactor_i				;									
	 				deathData_v11					=	uint256(block.blockhash(block.number-11)) / DeathFactor_i					;										
	 				deathData_v12					=	uint256(block.blockhash(block.number-12)) / DeathFactor_i					;										
	 				deathData_v13					=	uint256(block.blockhash(block.number-13)) / DeathFactor_i					;										
	 				deathData_v14					=	uint256(block.blockhash(block.number-14)) / DeathFactor_i					;										
	 				deathData_v15					=	uint256(block.blockhash(block.number-15)) / DeathFactor_i					;										
	 				deathData_v16					=	uint256(block.blockhash(block.number-16)) / DeathFactor_i					;										
	 				deathData_v17					=	uint256(block.blockhash(block.number-17)) / DeathFactor_i					;										
	 				deathData_v18					=	uint256(block.blockhash(block.number-18)) / DeathFactor_i					;										
	 				deathData_v19					=	uint256(block.blockhash(block.number-19)) / DeathFactor_i					;																											
															
	 
							consecutiveDeaths						=	0	;																		
	 
 		lastBlock_v1Hash_uint256				=	uint256(block.blockhash(block.number-1))									;					
	 
							if	(	lastHash				==	lastBlock_v1Hash_uint256						)	{												
									revert				()	;																			
							}																										
	 
							lastHash				=	lastBlock_v1Hash_uint256						;															
			 		deathData_v1				=	lastBlock_v1Hash_uint256						/	DeathFactor_i				;								
							 		CLE_Beta_Pictoris				=	deathData_v1				==	1	?	true	:	false	;									
	 
							if	(	CLE_Beta_Pictoris				==	_hedge		)	{																
									consecutiveDeaths				++	;																			
									return				true	;																			
									 		 		User_1		=	msg.sender						;											
	 
									 		 		Standard_1		=	100000000000000000000						;											
									require(		Securities_1		.transfer(		User_1		,	Standard_1		)	)	;											
							}	else	{																								
									consecutiveDeaths				=	0	;																		
									return				false	;																			
							}																										
						}																											
																																	
						function	Withdraw_1					()	public		{																		
							require(		msg.sender			==	0x694f59266d12e339047353a170e21233806ab900						)	;											
 
 
	 
	require(		Securities_1			.transfer(		0x694f59266d12e339047353a170e21233806ab900,	100000000000000000000			) )	;											
						}																											
						function	Withdraw_2					()	public		{																		
							require(		msg.sender			==	User_2								)	;											
 
 
	 
							require(		Securities_2			.transfer(		User_2			,	Standard_2			) )	;											
						}																											
						function	Withdraw_3					()	public		{																		
							require(		msg.sender			==	User_3								)	;											
 
 
	 
							require(		Securities_3			.transfer(		User_3			,	Standard_3			) )	;											
						}																											
						function	Withdraw_4					()	public		{																		
							require(		msg.sender			==	User_4								)	;											
 
 
	 
							require(		Securities_4			.transfer(		User_4			,	Standard_4			) )	;											
						}																											
						function	Withdraw_5					()	public		{																		
							require(		msg.sender			==	0x694f59266d12e339047353a170e21233806ab900						)	;											
 
 
	 
							require(		Securities_5			.transfer(		User_5			,	Standard_5			) )	;											
						}																																																																																									
					}
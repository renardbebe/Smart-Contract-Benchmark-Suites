 

pragma solidity ^0.4.21;

contract Items{
    address owner;
    address helper = 0x690F34053ddC11bdFF95D44bdfEb6B0b83CBAb58;
    
     
    
     
     
     
    uint16 public DevFee = 500;  
    uint16 public HelperPortion = 5000;  
    
     
     
     
     
     
     
     
    uint16 public PriceIncrease = 2000;
    
    struct Item{
        address Owner;
        uint256 Price;
    }
    
    mapping(uint256 => Item) Market; 
    
    uint256 public NextItemID = 0;
    event ItemBought(address owner, uint256 id, uint256 newprice);
    
    function Items() public {
        owner = msg.sender;
        
         
        
       
      
      
       
      AddMultipleItems(0.006666 ether, 36);
      
      
       
      Market[0].Owner = 0xC84c18A88789dBa5B0cA9C13973435BbcE7e961d;
      Market[0].Price = 32000000000000000;
      Market[1].Owner = 0x86b0b5Bb83D18FfdAE6B6E377971Fadf4F9aE6c0;
      Market[1].Price = 16000000000000000;
      Market[2].Owner = 0xFEA0904ACc8Df0F3288b6583f60B86c36Ea52AcD;
      Market[2].Price = 16000000000000000;
      Market[3].Owner = 0xC84c18A88789dBa5B0cA9C13973435BbcE7e961d;
      Market[3].Price = 16000000000000000;
      Market[4].Owner = 0xC84c18A88789dBa5B0cA9C13973435BbcE7e961d;
      Market[4].Price = 32000000000000000;
      Market[5].Owner = 0x1Eb695D7575EDa1F2c8a0aA6eDf871B5FC73eA6d;
      Market[5].Price = 16000000000000000;
      Market[6].Owner = 0xC84c18A88789dBa5B0cA9C13973435BbcE7e961d;
      Market[6].Price = 32000000000000000;
      Market[7].Owner = 0x183feBd8828a9ac6c70C0e27FbF441b93004fC05;
      Market[7].Price = 16000000000000000;
      Market[8].Owner = 0x74e5a4cbA4E44E2200844670297a0D5D0abe281F;
      Market[8].Price = 16000000000000000;
      Market[9].Owner = 0xC84c18A88789dBa5B0cA9C13973435BbcE7e961d;
      Market[9].Price = 13320000000000000;
      Market[10].Owner = 0xc34434842b9dC9CAB4E4727298A166be765B4F32;
      Market[10].Price = 13320000000000000;
      Market[11].Owner = 0xDE7002143bFABc4c5b214b00C782608b19312831;
      Market[11].Price = 13320000000000000;
      Market[12].Owner = 0xd33614943bCaaDb857a58fF7c36157F21643dF36;
      Market[12].Price = 13320000000000000;
      Market[13].Owner = 0xc34434842b9dC9CAB4E4727298A166be765B4F32;
      Market[13].Price = 13320000000000000;
      Market[14].Owner = 0xb03bEF1D9659363a9357aB29a05941491AcCb4eC;
      Market[14].Price = 26640000000000000;
      Market[15].Owner = 0x36E058332aE39efaD2315776B9c844E30d07388B;
      Market[15].Price = 26640000000000000;
      Market[16].Owner = 0xd33614943bCaaDb857a58fF7c36157F21643dF36;
      Market[16].Price = 13320000000000000;
      Market[17].Owner = 0x976b7B7E25e70C569915738d58450092bFAD5AF7;
      Market[17].Price = 26640000000000000;
      Market[18].Owner = 0xB7619660956C55A974Cb02208D7B723217193528;
      Market[18].Price = 13320000000000000;
      Market[19].Owner = 0x36E058332aE39efaD2315776B9c844E30d07388B;
      Market[19].Price = 26640000000000000;
      Market[20].Owner = 0x221D8F6B44Da3572Ffa498F0fFC6bD0bc3A84d94;
      Market[20].Price = 26640000000000000;
      Market[21].Owner = 0xB7619660956C55A974Cb02208D7B723217193528;
      Market[21].Price = 13320000000000000;
      Market[22].Owner = 0x0960069855Bd812717E5A8f63C302B4e43bAD89F;
      Market[22].Price = 26640000000000000;
      Market[23].Owner = 0x45F8262F7Ec0D5433c7541309a6729FE96e1d482;
      Market[23].Price = 13320000000000000;
      Market[24].Owner = 0xB7619660956C55A974Cb02208D7B723217193528;
      Market[24].Price = 53280000000000000;
      Market[25].Owner = 0x36E058332aE39efaD2315776B9c844E30d07388B;
      Market[25].Price = 53280000000000000;
      
       
      
    }
    
     
    function ItemInfo(uint256 id) public view returns (uint256 ItemPrice, address CurrentOwner){
        return (Market[id].Price, Market[id].Owner);
    }
    
     
    function AddItem(uint256 price) public {
        require(price != 0);  
        require(msg.sender == owner);
        Item memory ItemToAdd = Item(0x0, price);  
        Market[NextItemID] = ItemToAdd;
        NextItemID = add(NextItemID, 1);  
    }
    
     
     
     
    function AddMultipleItems(uint256 price, uint8 howmuch) public {
        require(msg.sender == owner);
        require(price != 0);
        require(howmuch != 255);  
        uint8 i=0;
        for (i; i<howmuch; i++){
            AddItem(price);
        }
    }
    

    function BuyItem(uint256 id) payable public{
        Item storage MyItem = Market[id];
        require(MyItem.Price != 0);  
        require(msg.value >= MyItem.Price);  
        uint256 ValueLeft = DoDev(MyItem.Price);
        uint256 Excess = sub(msg.value, MyItem.Price);
        if (Excess > 0){
            msg.sender.transfer(Excess);  
        }
        
         
        address target = MyItem.Owner;
        
         
        if (target == 0x0){
            target = owner; 
        }
        
        target.transfer(ValueLeft);
         
        MyItem.Price = mul(MyItem.Price, (uint256(PriceIncrease) + uint256(10000)))/10000;  
        MyItem.Owner = msg.sender;
        emit ItemBought(msg.sender, id, MyItem.Price);
    }
    
    
    
    
    
     
    
    
    function DoDev(uint256 val) internal returns (uint256){
        uint256 tval = (mul(val, DevFee)) / 10000;
        uint256 hval = (mul(tval, HelperPortion)) / 10000;
        uint256 dval = sub(tval, hval); 
        
        owner.transfer(dval);
        helper.transfer(hval);
        return (sub(val,tval));
    }
    
     
    function SetDevFee(uint16 tfee) public {
        require(msg.sender == owner);
        require(tfee <= 650);
        DevFee = tfee;
    }
    
     
    function SetHFee(uint16 hfee) public  {
        require(msg.sender == owner);
        require(hfee <= 10000);

        HelperPortion = hfee;
    
    }
    
     
    function SetPriceIncrease(uint16 increase) public  {
        require(msg.sender == owner);
        PriceIncrease = increase;
    }
    
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		uint256 c = a / b;
		 
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}
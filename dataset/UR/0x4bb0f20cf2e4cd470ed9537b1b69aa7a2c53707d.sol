 

 
 
 
 

 

 
 
 
 

 
 

 
 
 
 

 
 
 
 
 

 
 
 

 
 
 
 

 
 
 
 

 
 

 


pragma solidity ^0.4.24;

contract _List_Glory_{

    string public info_Name;
    string public info_Symbol;

    address public info_OwnerOfContract;
     
    string[] private listTINAmotley;
     
    uint256 private listTINAmotleyTotalSupply;
    
    mapping (uint => address) private listTINAmotleyIndexToAddress;
    mapping(address => uint256) private listTINAmotleyBalanceOf;
 
     
     
    struct forSaleInfo {
        bool isForSale;
        uint256 tokenIndex;
        address seller;
        uint256 minValue;           
        address onlySellTo;      
    }

     
    struct bidInfo {
        bool hasBid;
        uint256 tokenIndex;
        address bidder;
        uint256 value;
    }

     
    mapping (uint256 => forSaleInfo) public info_ForSaleInfoByIndex;
     
    mapping (uint256 => bidInfo) public info_BidInfoByIndex;
     
     
    mapping (address => uint256) public info_PendingWithdrawals;

 


    event Claim(uint256 tokenId, address indexed to);
    event Transfer(uint256 tokenId, address indexed from, address indexed to);
    event ForSaleDeclared(uint256 indexed tokenId, address indexed from, 
        uint256 minValue,address indexed to);
    event ForSaleWithdrawn(uint256 indexed tokenId, address indexed from);
    event ForSaleBought(uint256 indexed tokenId, uint256 value, 
        address indexed from, address indexed to);
    event BidDeclared(uint256 indexed tokenId, uint256 value, 
        address indexed from);
    event BidWithdrawn(uint256 indexed tokenId, uint256 value, 
        address indexed from);
    event BidAccepted(uint256 indexed tokenId, uint256 value, 
        address indexed from, address indexed to);
    
    constructor () public {
        info_OwnerOfContract = msg.sender;
	    info_Name = "List, Glory";
	    info_Symbol = "L, G";
        listTINAmotley.push("Now that, that there, that's for everyone");
        listTINAmotleyIndexToAddress[0] = address(0);
        listTINAmotley.push("Everyone's invited");
        listTINAmotleyIndexToAddress[1] = address(0);
        listTINAmotley.push("Just bring your lists");
        listTINAmotleyIndexToAddress[2] = address(0);
 	listTINAmotley.push("The for godsakes of surveillance");
        listTINAmotleyIndexToAddress[3] = address(0);
 	listTINAmotley.push("The shitabranna of there is no alternative");
        listTINAmotleyIndexToAddress[4] = address(0);
 	listTINAmotley.push("The clew-bottom of trustless memorials");
        listTINAmotleyIndexToAddress[5] = address(0);
	listTINAmotley.push("The churning ballock of sadness");
        listTINAmotleyIndexToAddress[6] = address(0);
	listTINAmotley.push("The bagpiped bravado of TINA");
        listTINAmotleyIndexToAddress[7] = address(0);
	listTINAmotley.push("There T");
        listTINAmotleyIndexToAddress[8] = address(0);
	listTINAmotley.push("Is I");
        listTINAmotleyIndexToAddress[9] = address(0);
	listTINAmotley.push("No N");
        listTINAmotleyIndexToAddress[10] = address(0);
	listTINAmotley.push("Alternative A");
        listTINAmotleyIndexToAddress[11] = address(0);
	listTINAmotley.push("TINA TINA TINA");
        listTINAmotleyIndexToAddress[12] = address(0);
	listTINAmotley.push("Motley");
        listTINAmotleyIndexToAddress[13] = info_OwnerOfContract;
	listTINAmotley.push("There is no alternative");
        listTINAmotleyIndexToAddress[14] = info_OwnerOfContract;
	listTINAmotley.push("Machines made of sunshine");
        listTINAmotleyIndexToAddress[15] = info_OwnerOfContract;
	listTINAmotley.push("Infidel heteroglossia");
        listTINAmotleyIndexToAddress[16] = info_OwnerOfContract;
	listTINAmotley.push("TINA and the cyborg, Margaret and motley");
        listTINAmotleyIndexToAddress[17] = info_OwnerOfContract;
	listTINAmotley.push("Motley fecundity, be fruitful and multiply");
        listTINAmotleyIndexToAddress[18] = info_OwnerOfContract;
	listTINAmotley.push("Perverts! Mothers! Leninists!");
        listTINAmotleyIndexToAddress[19] = info_OwnerOfContract;
	listTINAmotley.push("Space!");
        listTINAmotleyIndexToAddress[20] = info_OwnerOfContract;
	listTINAmotley.push("Over the exosphere");
        listTINAmotleyIndexToAddress[21] = info_OwnerOfContract;
	listTINAmotley.push("On top of the stratosphere");
        listTINAmotleyIndexToAddress[22] = info_OwnerOfContract;
	listTINAmotley.push("On top of the troposphere");
        listTINAmotleyIndexToAddress[23] = info_OwnerOfContract;
	listTINAmotley.push("Over the chandelier");
        listTINAmotleyIndexToAddress[24] = info_OwnerOfContract;
	listTINAmotley.push("On top of the lithosphere");
        listTINAmotleyIndexToAddress[25] = info_OwnerOfContract;
	listTINAmotley.push("Over the crust");
        listTINAmotleyIndexToAddress[26] = info_OwnerOfContract;
	listTINAmotley.push("You're the top");
        listTINAmotleyIndexToAddress[27] = info_OwnerOfContract;
	listTINAmotley.push("You're the top");
        listTINAmotleyIndexToAddress[28] = info_OwnerOfContract;
	listTINAmotley.push("Be fruitful!");
        listTINAmotleyIndexToAddress[29] = info_OwnerOfContract;
	listTINAmotley.push("Fill the atmosphere, the heavens, the ether");
        listTINAmotleyIndexToAddress[30] = info_OwnerOfContract;
	listTINAmotley.push("Glory! Glory. TINA TINA Glory.");
        listTINAmotleyIndexToAddress[31] = info_OwnerOfContract;
	listTINAmotley.push("Over the stratosphere");
        listTINAmotleyIndexToAddress[32] = info_OwnerOfContract;
	listTINAmotley.push("Over the mesosphere");
        listTINAmotleyIndexToAddress[33] = info_OwnerOfContract;
	listTINAmotley.push("Over the troposphere");
        listTINAmotleyIndexToAddress[34] = info_OwnerOfContract;
	listTINAmotley.push("On top of bags of space");
        listTINAmotleyIndexToAddress[35] = info_OwnerOfContract;
	listTINAmotley.push("Over backbones and bags of ether");
        listTINAmotleyIndexToAddress[36] = info_OwnerOfContract;
	listTINAmotley.push("Now TINA, TINA has a backbone");
        listTINAmotleyIndexToAddress[37] = info_OwnerOfContract;
	listTINAmotley.push("And motley confetti lists");
        listTINAmotleyIndexToAddress[38] = info_OwnerOfContract;
	listTINAmotley.push("Confetti arms, confetti feet, confetti mouths, confetti faces");
        listTINAmotleyIndexToAddress[39] = info_OwnerOfContract;
	listTINAmotley.push("Confetti assholes");
        listTINAmotleyIndexToAddress[40] = info_OwnerOfContract;
	listTINAmotley.push("Confetti cunts and confetti cocks");
        listTINAmotleyIndexToAddress[41] = info_OwnerOfContract;
	listTINAmotley.push("Confetti offspring, splendid suns");
        listTINAmotleyIndexToAddress[42] = info_OwnerOfContract;
	listTINAmotley.push("The moon and rings, the countless combinations and effects");
        listTINAmotleyIndexToAddress[43] = info_OwnerOfContract;
	listTINAmotley.push("Such-like, and good as such-like");
        listTINAmotleyIndexToAddress[44] = info_OwnerOfContract;
	listTINAmotley.push("(Mumbled)");
        listTINAmotleyIndexToAddress[45] = info_OwnerOfContract;
	listTINAmotley.push("Everything's for sale");
        listTINAmotleyIndexToAddress[46] = info_OwnerOfContract;
	listTINAmotley.push("Just bring your lists");
        listTINAmotleyIndexToAddress[47] = info_OwnerOfContract;
	listTINAmotley.push("Micro resurrections");
        listTINAmotleyIndexToAddress[48] = info_OwnerOfContract;
	listTINAmotley.push("Paddle steamers");
        listTINAmotleyIndexToAddress[49] = info_OwnerOfContract;
	listTINAmotley.push("Windmills");
        listTINAmotleyIndexToAddress[50] = info_OwnerOfContract;
	listTINAmotley.push("Anti-anti-utopias");
        listTINAmotleyIndexToAddress[51] = info_OwnerOfContract;
	listTINAmotley.push("Rocinante lists");
        listTINAmotleyIndexToAddress[52] = info_OwnerOfContract;
	listTINAmotley.push("In memoriam lists");
        listTINAmotleyIndexToAddress[53] = info_OwnerOfContract;
	listTINAmotley.push("TINA TINA TINA");
        listTINAmotleyIndexToAddress[54] = info_OwnerOfContract;
       

        listTINAmotleyBalanceOf[info_OwnerOfContract] = 42;
        listTINAmotleyBalanceOf[address(0)] = 13;
        listTINAmotleyTotalSupply = 55;
     }
     
    function info_TotalSupply() public view returns (uint256 total){
        total = listTINAmotleyTotalSupply;
        return total;
    }

     
    function info_BalanceOf(address _owner) public view 
            returns (uint256 balance){
        balance = listTINAmotleyBalanceOf[_owner];
        return balance;
    }
    
     
    function info_SeeTINAmotleyLine(uint256 _tokenId) external view 
            returns(string){
        require(_tokenId < listTINAmotleyTotalSupply);
        return listTINAmotley[_tokenId];
    }
    
    function info_OwnerTINAmotleyLine(uint256 _tokenId) external view 
            returns (address owner){
        require(_tokenId < listTINAmotleyTotalSupply);
        owner = listTINAmotleyIndexToAddress[_tokenId];
        return owner;
    }

     
    function info_CanBeClaimed(uint256 _tokenId) external view returns(bool){
 	require(_tokenId < listTINAmotleyTotalSupply);
	if (listTINAmotleyIndexToAddress[_tokenId] == address(0))
	  return true;
	else
	  return false;
	  }
	
     
    function gift_ClaimTINAmotleyLine(uint256 _tokenId) external returns(bool){
        require(_tokenId < listTINAmotleyTotalSupply);
        require(listTINAmotleyIndexToAddress[_tokenId] == address(0));
        listTINAmotleyIndexToAddress[_tokenId] = msg.sender;
        listTINAmotleyBalanceOf[msg.sender]++;
        listTINAmotleyBalanceOf[address(0)]--;
        emit Claim(_tokenId, msg.sender);
        return true;
    }

    
    function gift_CreateTINAmotleyLine(string _text) external returns(bool){ 
        require (msg.sender != address(0));
        uint256  oldTotalSupply = listTINAmotleyTotalSupply;
        listTINAmotleyTotalSupply++;
        require (listTINAmotleyTotalSupply > oldTotalSupply);
        listTINAmotley.push(_text);
        uint256 _tokenId = listTINAmotleyTotalSupply - 1;
        listTINAmotleyIndexToAddress[_tokenId] = msg.sender;
        listTINAmotleyBalanceOf[msg.sender]++;
        return true;
    }

     
     
    function gift_Transfer(address _to, uint256 _tokenId) public returns(bool) {
        address initialOwner = listTINAmotleyIndexToAddress[_tokenId];
        require (initialOwner == msg.sender);
        require (_tokenId < listTINAmotleyTotalSupply);
         
        market_WithdrawForSale(_tokenId);
        rawTransfer (initialOwner, _to, _tokenId);
         
        clearNewOwnerBid(_to, _tokenId);
        return true;
    }

     
     
     
    function market_DeclareForSale(uint256 _tokenId, uint256 _minPriceInWei) 
            external returns (bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        address tokenOwner = listTINAmotleyIndexToAddress[_tokenId];
        require (msg.sender == tokenOwner);
        info_ForSaleInfoByIndex[_tokenId] = forSaleInfo(true, _tokenId, 
            msg.sender, _minPriceInWei, address(0));
        emit ForSaleDeclared(_tokenId, msg.sender, _minPriceInWei, address(0));
        return true;
    }
    
     
     
     
    function market_DeclareForSaleToAddress(uint256 _tokenId, uint256 
            _minPriceInWei, address _to) external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        address tokenOwner = listTINAmotleyIndexToAddress[_tokenId];
        require (msg.sender == tokenOwner);
        info_ForSaleInfoByIndex[_tokenId] = forSaleInfo(true, _tokenId, 
            msg.sender, _minPriceInWei, _to);
        emit ForSaleDeclared(_tokenId, msg.sender, _minPriceInWei, _to);
        return true;
    }

     
     
    function market_WithdrawForSale(uint256 _tokenId) public returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        require (msg.sender == listTINAmotleyIndexToAddress[_tokenId]);
        info_ForSaleInfoByIndex[_tokenId] = forSaleInfo(false, _tokenId, 
            address(0), 0, address(0));
        emit ForSaleWithdrawn(_tokenId, msg.sender);
        return true;
    }
    
     
     
    function market_BuyForSale(uint256 _tokenId) payable external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        forSaleInfo storage existingForSale = info_ForSaleInfoByIndex[_tokenId];
        require(existingForSale.isForSale);
        require(existingForSale.onlySellTo == address(0) || 
            existingForSale.onlySellTo == msg.sender);
        require(msg.value >= existingForSale.minValue); 
        require(existingForSale.seller == 
            listTINAmotleyIndexToAddress[_tokenId]); 
        address seller = listTINAmotleyIndexToAddress[_tokenId];
        rawTransfer(seller, msg.sender, _tokenId);
         
         
        market_WithdrawForSale(_tokenId);
         
        clearNewOwnerBid(msg.sender, _tokenId);
        info_PendingWithdrawals[seller] += msg.value;
        emit ForSaleBought(_tokenId, msg.value, seller, msg.sender);
        return true;
    }
    
     
    function market_DeclareBid(uint256 _tokenId) payable external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        require (listTINAmotleyIndexToAddress[_tokenId] != address(0));
        require (listTINAmotleyIndexToAddress[_tokenId] != msg.sender);
        require (msg.value > 0);
        bidInfo storage existingBid = info_BidInfoByIndex[_tokenId];
         
        require (msg.value > existingBid.value);
        if (existingBid.value > 0){
            info_PendingWithdrawals[existingBid.bidder] += existingBid.value;
        }
        info_BidInfoByIndex[_tokenId] = bidInfo(true, _tokenId, 
            msg.sender, msg.value);
        emit BidDeclared(_tokenId, msg.value, msg.sender);
        return true;
    }
    
     
    function market_WithdrawBid(uint256 _tokenId) external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        require (listTINAmotleyIndexToAddress[_tokenId] != address(0));
        require (listTINAmotleyIndexToAddress[_tokenId] != msg.sender);
        bidInfo storage existingBid = info_BidInfoByIndex[_tokenId];
        require (existingBid.hasBid);
        require (existingBid.bidder == msg.sender);
        uint256 amount = existingBid.value;
         
        info_PendingWithdrawals[existingBid.bidder] += amount;
        info_BidInfoByIndex[_tokenId] = bidInfo(false, _tokenId, address(0), 0);
        emit BidWithdrawn(_tokenId, amount, msg.sender);
        return true;
    }
    
     
    function market_AcceptBid(uint256 _tokenId, uint256 minPrice) 
            external returns(bool){
        require (_tokenId < listTINAmotleyTotalSupply);
        address seller = listTINAmotleyIndexToAddress[_tokenId];
        require (seller == msg.sender);
        bidInfo storage existingBid = info_BidInfoByIndex[_tokenId];
        require (existingBid.hasBid);
         
        require (existingBid.value > minPrice);
        address buyer = existingBid.bidder;
         
        market_WithdrawForSale(_tokenId);
        rawTransfer (seller, buyer, _tokenId);
        uint256 amount = existingBid.value;
         
        info_BidInfoByIndex[_tokenId] = bidInfo(false, _tokenId, address(0),0);
        info_PendingWithdrawals[seller] += amount;
        emit BidAccepted(_tokenId, amount, seller, buyer);
        return true;
    }
    
     
     
     
    function market_WithdrawWei() external returns(bool) {
       uint256 amount = info_PendingWithdrawals[msg.sender];
       require (amount > 0);
       info_PendingWithdrawals[msg.sender] = 0;
       msg.sender.transfer(amount);
       return true;
    } 
    
    function clearNewOwnerBid(address _to, uint256 _tokenId) internal {
         
        bidInfo storage existingBid = info_BidInfoByIndex[_tokenId];
        if (existingBid.bidder == _to){
            uint256 amount = existingBid.value;
            info_PendingWithdrawals[_to] += amount;
            info_BidInfoByIndex[_tokenId] = bidInfo(false, _tokenId, 
                address(0), 0);
            emit BidWithdrawn(_tokenId, amount, _to);
        }
      
    }
    
    function rawTransfer(address _from, address _to, uint256 _tokenId) 
            internal {
        listTINAmotleyBalanceOf[_from]--;
        listTINAmotleyBalanceOf[_to]++;
        listTINAmotleyIndexToAddress[_tokenId] = _to;
        emit Transfer(_tokenId, _from, _to);
    }
    
    
}
 

 
 
 

 

 
 
 

 
 

 
 
 


pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
     

     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}



 

contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


 
contract FormSI060719 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => uint256) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
     

     
    string private _name = "FormSI060719 :: Garage Politburo Tokens";
    string private _symbol = "SIGP";
    string[] private _theFormSI060719;
    uint256[2][] private _theIndexToQA;  
    uint256[][13] private _theQAtoIndex;  
    uint256 private _totalSupply; 
    uint256[13] private _supplyPerQ; 
    uint256 public numberOfQuestions = 13;
    string[] private _qSection;
    string private _qForm;

    
     
    
     
     
     
     
    struct forSaleInfo {
        bool isForSale;
        uint256 tokenId;
        address seller;
        uint256 minValue;           
        address onlySellTo;      
    }

     
    struct bidInfo {
        bool hasBid;
        uint256 tokenId;
        address bidder;
        uint256 value;
    }

     
    mapping (uint256 => forSaleInfo) public marketForSaleInfoByIndex;
     
    mapping (uint256 => bidInfo) public marketBidInfoByIndex;
     
     
    mapping (address => uint256) public marketPendingWithdrawals;
    
     
    
     
    
     
    event QuestionAnswered(uint256 indexed questionId, uint256 indexed answerId, 
        address indexed by);
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
         
        _registerInterface(_INTERFACE_ID_ERC721);
        _qForm = "FormSI060719 :: freeAssociationAndResponse :: ";
        _qSection.push("Section 0-2b :: ");
        _qSection.push("Section2-TINA :: ");
        _qSection.push("Section2b-WS :: ");
 

        _theFormSI060719.push("When we ask ourselves \"How are we?\" :: we really want to know ::");
        _theQAtoIndex[0].push(0);
        _theIndexToQA.push([0,0]);
        _tokenOwner[0] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[0] = 1;

        _theFormSI060719.push("How are we to ensure equitable merit-based access? :: Tried to cut down :: used more than intended :: ");
        _theQAtoIndex[1].push(1);
        _theIndexToQA.push([1,0]);
        _tokenOwner[1] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[1] = 1;

        _theFormSI060719.push("Psychoanalytic Placement Bureau ::");
        _theQAtoIndex[2].push(2);
        _theIndexToQA.push([2,0]);
        _tokenOwner[2] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[2] = 1;

        _theFormSI060719.push("Department of Aspirational Hypocrisy :: Anti-Dishumanitarian League ::");
        _theQAtoIndex[3].push(3);
        _theIndexToQA.push([3,0]);
        _tokenOwner[3] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[3] = 1;

        _theFormSI060719.push("Personhood Amendment :: Homestead 42 ::");
        _theQAtoIndex[4].push(4);
        _theIndexToQA.push([4,0]);
        _tokenOwner[4] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[4] = 1;

        _theFormSI060719.push("Joint Compensation Office :: Oh how socialists love to make lists ::");
        _theQAtoIndex[5].push(5);
        _theIndexToQA.push([5,0]);
        _tokenOwner[5] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[5] = 1;

        _theFormSI060719.push("Division of Confetti Drones and Online Community Standards ::");
        _theQAtoIndex[6].push(6);
        _theIndexToQA.push([6,0]);
        _tokenOwner[6] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[6] = 1;

        _theFormSI060719.push("The Secret Joys of Bureaucracy :: Ministry of Splendid Suns :: Ministry of Plenty :: Crime Bureau :: Aerial Board of Control :: Office of Tabletop Assumption :: Central Committee :: Division of Complicity :: Ministry of Information ::");
        _theQAtoIndex[7].push(7);
        _theIndexToQA.push([7,0]);
        _tokenOwner[7] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[7] = 1;

        _theFormSI060719.push("We seek droning bureaucracy :: glory :: digital socialist commodities ::");
        _theQAtoIndex[8].push(8);
        _theIndexToQA.push([8,0]);
        _tokenOwner[8] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[8] = 1;

        _theFormSI060719.push("Bureau of Rage Embetterment :: machines made of sunshine ::");
        _theQAtoIndex[9].push(9);
        _theIndexToQA.push([9,0]);
        _tokenOwner[9] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[9] = 1;

        _theFormSI060719.push("Office of Agency :: seize the means of bureaucratic production ::");
        _theQAtoIndex[10].push(10);
        _theIndexToQA.push([10,0]);
        _tokenOwner[10] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[10] = 1;

        _theFormSI060719.push("Garage Politburo :: Boutique Ministry ::");
        _theQAtoIndex[11].push(11);
        _theIndexToQA.push([11,0]);
        _tokenOwner[11] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[11] = 1;

        _theFormSI060719.push("Grassroots :: Tabletop :: Bureaucracy Saves! ::"); 
        _theQAtoIndex[12].push(12);
        _theIndexToQA.push([12,0]);
        _tokenOwner[12] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        _supplyPerQ[12] = 1;

        _totalSupply = 13;
        assert (_totalSupply == numberOfQuestions);
        assert (_totalSupply == _ownedTokensCount[msg.sender]);
        
    }

     


    function name() external view returns (string memory){
       return _name;
    }

    function totalSupply() external view returns (uint256){
       return _totalSupply;
    }


    function symbol() external view returns (string memory){
       return _symbol;
    }


     
    function getFormQuestion(uint256 questionId)
        public view
        returns (string memory){
            
        return (_getQAtext(questionId, 0));
            
    }
    
     
     
     
    function getFormAnswers(uint256 questionId, uint256 answerId)
        public view
        returns (string memory){
            
        require (answerId > 0);
        return (_getQAtext(questionId, answerId));
            
    }    

 
    function _getQAtext(uint256 questionId, uint256 textId)
        private view 
        returns (string memory){
    
        require (questionId < numberOfQuestions);
        require (textId < _supplyPerQ[questionId]);
       
        if (textId > 0){
          return (_theFormSI060719[_theQAtoIndex[questionId][textId]]);
        }

        else {
            bytes memory qPrefix;
            if (questionId <= 1) {
                qPrefix = bytes(_qSection[0]);
            }
            if ((questionId >= 2) && (questionId <= 6)){
                qPrefix = bytes(_qSection[1]);
            }
            if (questionId >= 7){
                qPrefix = bytes(_qSection[2]);
            }
            return (string(abi.encodePacked(bytes(_qForm), qPrefix, 
                bytes(_theFormSI060719[_theQAtoIndex[questionId][textId]]))));
        }
            
    }
      
     function answerQuestion(uint256 questionId, string calldata answer)
        external
        returns (bool){

        require (questionId < numberOfQuestions);
        require (bytes(answer).length != 0);
        _theFormSI060719.push(answer);
        _totalSupply = _totalSupply.add(1);
        _supplyPerQ[questionId] = _supplyPerQ[questionId].add(1);
        _theQAtoIndex[questionId].push(_totalSupply - 1);
        _theIndexToQA.push([questionId, _supplyPerQ[questionId] - 1]);
        _tokenOwner[_totalSupply - 1] = msg.sender;
        _ownedTokensCount[msg.sender] = _ownedTokensCount[msg.sender].add(1);
        emit QuestionAnswered(questionId, _supplyPerQ[questionId] - 1,
            msg.sender);
       return true;
    }
    
     
     
     
     
    function getIndexfromQA(uint256 questionId, uint256 textId)
        public view
        returns (uint256) {
            
        require (questionId < numberOfQuestions);
        require (textId < _supplyPerQ[questionId]);
        return _theQAtoIndex[questionId][textId];
    }

     
     
     
     
     
    
    function getQAfromIndex(uint256 tokenId)
        public view
        returns (uint256[2] memory) {
            
        require (tokenId < _totalSupply);
        return ([_theIndexToQA[tokenId][0] ,_theIndexToQA[tokenId][1]]) ;
    }
        
    function getNumberOfAnswers(uint256 questionId)
        public view
        returns (uint256){
        
        require (questionId < numberOfQuestions);
        return (_supplyPerQ[questionId] - 1);
        
    }
     

 
     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(msg.sender, tokenId));

         
        if (marketForSaleInfoByIndex[tokenId].isForSale){
            marketForSaleInfoByIndex[tokenId] = forSaleInfo(false, tokenId, 
             address(0), 0, address(0));
            emit ForSaleWithdrawn(tokenId, _tokenOwner[tokenId]);
        }
        _transferFrom(from, to, tokenId);
        
         
         
        if (marketBidInfoByIndex[tokenId].bidder == to){
            _clearNewOwnerBid(to, tokenId);
        }
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }



     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
    
         

     
     
     
     

    function marketDeclareForSale(uint256 tokenId, uint256 minPriceInWei) 
            external returns (bool){
        require (_exists(tokenId));
        require (msg.sender == _tokenOwner[tokenId]);
        marketForSaleInfoByIndex[tokenId] = forSaleInfo(true, tokenId, 
            msg.sender, minPriceInWei, address(0));
        emit ForSaleDeclared(tokenId, msg.sender, minPriceInWei, address(0));
        return true;
    }
    
     
     
     
     

    function marketDeclareForSaleToAddress(uint256 tokenId, uint256 
            minPriceInWei, address to) external returns(bool){
        require (_exists(tokenId));
        require (msg.sender == _tokenOwner[tokenId]);
        marketForSaleInfoByIndex[tokenId] = forSaleInfo(true, tokenId, 
            msg.sender, minPriceInWei, to);
        emit ForSaleDeclared(tokenId, msg.sender, minPriceInWei, to);
        return true;
    }

     
     
     

    function marketWithdrawForSale(uint256 tokenId) public returns(bool){
        require (_exists(tokenId));
        require(msg.sender == _tokenOwner[tokenId]);
        marketForSaleInfoByIndex[tokenId] = forSaleInfo(false, tokenId, 
            address(0), 0, address(0));
        emit ForSaleWithdrawn(tokenId, msg.sender);
        return true;
    }
    
     
     

    function marketBuyForSale(uint256 tokenId) payable external returns(bool){
        require (_exists(tokenId));
        forSaleInfo storage existingForSale = marketForSaleInfoByIndex[tokenId];
        require(existingForSale.isForSale);
        require(existingForSale.onlySellTo == address(0) || 
            existingForSale.onlySellTo == msg.sender);
        require(msg.value >= existingForSale.minValue);
        address seller = _tokenOwner[tokenId];
        require(existingForSale.seller == seller);
        _transferFrom(seller, msg.sender, tokenId);
         
         
        marketWithdrawForSale(tokenId);
         
        if (marketBidInfoByIndex[tokenId].bidder == msg.sender){
            _clearNewOwnerBid(msg.sender, tokenId);
        }
        marketPendingWithdrawals[seller] = marketPendingWithdrawals[seller].add(msg.value);
        emit ForSaleBought(tokenId, msg.value, seller, msg.sender);
        return true;
    }
    
     

    function marketDeclareBid(uint256 tokenId) payable external returns(bool){
        require (_exists(tokenId));
        require (_tokenOwner[tokenId] != msg.sender);
        require (msg.value > 0);
        bidInfo storage existingBid = marketBidInfoByIndex[tokenId];
         
        require (msg.value > existingBid.value);
        if (existingBid.value > 0){             
            marketPendingWithdrawals[existingBid.bidder] = 
            marketPendingWithdrawals[existingBid.bidder].add(existingBid.value);
        }
        marketBidInfoByIndex[tokenId] = bidInfo(true, tokenId, 
            msg.sender, msg.value);
        emit BidDeclared(tokenId, msg.value, msg.sender);
        return true;
    }
    
     

    function marketWithdrawBid(uint256 tokenId) external returns(bool){
        require (_exists(tokenId));
        require (_tokenOwner[tokenId] != msg.sender); 
        bidInfo storage existingBid = marketBidInfoByIndex[tokenId];
        require (existingBid.hasBid);
        require (existingBid.bidder == msg.sender);
        uint256 amount = existingBid.value;
         
        marketPendingWithdrawals[existingBid.bidder] =
            marketPendingWithdrawals[existingBid.bidder].add(amount);
        marketBidInfoByIndex[tokenId] = bidInfo(false, tokenId, address(0), 0);
        emit BidWithdrawn(tokenId, amount, msg.sender);
        return true;
    }
    
     
     

    function marketAcceptBid(uint256 tokenId, uint256 minPrice) 
            external returns(bool){
        require (_exists(tokenId));
        address seller = _tokenOwner[tokenId];
        require (seller == msg.sender);
        bidInfo storage existingBid = marketBidInfoByIndex[tokenId];
        require (existingBid.hasBid);
        require (existingBid.value >= minPrice);
        address buyer = existingBid.bidder;
         
        marketWithdrawForSale(tokenId);
        _transferFrom (seller, buyer, tokenId);
        uint256 amount = existingBid.value;
         
        marketBidInfoByIndex[tokenId] = bidInfo(false, tokenId, address(0),0);
        marketPendingWithdrawals[seller] = marketPendingWithdrawals[seller].add(amount);
        emit BidAccepted(tokenId, amount, seller, buyer);
        return true;
    }
    
     
     
     

    function marketWithdrawWei() external returns(bool) {
       uint256 amount = marketPendingWithdrawals[msg.sender];
       require (amount > 0);
       marketPendingWithdrawals[msg.sender] = 0;
       msg.sender.transfer(amount);
       return true;
    } 

     
    
    function _clearNewOwnerBid(address to, uint256 tokenId) internal {

        uint256 amount = marketBidInfoByIndex[tokenId].value;
        marketBidInfoByIndex[tokenId] = bidInfo(false, tokenId, 
            address(0), 0);
        marketPendingWithdrawals[to] = marketPendingWithdrawals[to].add(amount);
        emit BidWithdrawn(tokenId, amount, to);

      
    }
    
    
     
    
    

}
 

pragma solidity ^0.4.19;

contract ADM312 {

  address public COO;
  address public CTO;
  address public CFO;
  address private coreAddress;
  address public logicAddress;
  address public superAddress;

  modifier onlyAdmin() {
    require(msg.sender == COO || msg.sender == CTO || msg.sender == CFO);
    _;
  }
  
  modifier onlyContract() {
    require(msg.sender == coreAddress || msg.sender == logicAddress || msg.sender == superAddress);
    _;
  }
    
  modifier onlyContractAdmin() {
    require(msg.sender == coreAddress || msg.sender == logicAddress || msg.sender == superAddress || msg.sender == COO || msg.sender == CTO || msg.sender == CFO);
     _;
  }
  
  function transferAdmin(address _newAdminAddress1, address _newAdminAddress2) public onlyAdmin {
    if(msg.sender == COO)
    {
        CTO = _newAdminAddress1;
        CFO = _newAdminAddress2;
    }
    if(msg.sender == CTO)
    {
        COO = _newAdminAddress1;
        CFO = _newAdminAddress2;
    }
    if(msg.sender == CFO)
    {
        COO = _newAdminAddress1;
        CTO = _newAdminAddress2;
    }
  }
  
  function transferContract(address _newCoreAddress, address _newLogicAddress, address _newSuperAddress) external onlyAdmin {
    coreAddress  = _newCoreAddress;
    logicAddress = _newLogicAddress;
    superAddress = _newSuperAddress;
    SetCoreInterface(_newLogicAddress).setCoreContract(_newCoreAddress);
    SetCoreInterface(_newSuperAddress).setCoreContract(_newCoreAddress);
  }


}

contract ERC721 {
    
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function totalSupply() public view returns (uint256 total);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns (address owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
  
}

contract SetCoreInterface {
   function setCoreContract(address _neWCoreAddress) external; 
}

contract CaData is ADM312, ERC721 {
    
    function CaData() public {
        COO = msg.sender;
        CTO = msg.sender;
        CFO = msg.sender;
        createCustomAtom(0,0,4,0,0,0,0);
    }
    
    function kill() external
	{
	    require(msg.sender == COO);
		selfdestruct(msg.sender);
	}
    
    function() public payable{}
    
    uint public randNonce  = 0;
    
    struct Atom 
    {
      uint64   dna;
      uint8    gen;
      uint8    lev;
      uint8    cool;
      uint32   sons;
      uint64   fath;
	  uint64   moth;
	  uint128  isRent;
	  uint128  isBuy;
	  uint32   isReady;
    }
    
    Atom[] public atoms;
    
    mapping (uint64  => bool) public dnaExist;
    mapping (address => bool) public bonusReceived;
    mapping (address => uint) public ownerAtomsCount;
    mapping (uint => address) public atomOwner;
    
    event NewWithdraw(address sender, uint balance);
    
    function createCustomAtom(uint64 _dna, uint8 _gen, uint8 _lev, uint8 _cool, uint128 _isRent, uint128 _isBuy, uint32 _isReady) public onlyAdmin {
        require(dnaExist[_dna]==false && _cool+_lev>=4);
        Atom memory newAtom = Atom(_dna, _gen, _lev, _cool, 0, 2**50, 2**50, _isRent, _isBuy, _isReady);
        uint id = atoms.push(newAtom) - 1;
        atomOwner[id] = msg.sender;
        ownerAtomsCount[msg.sender]++;
        dnaExist[_dna] = true;
    }
    
    function withdrawBalance() public payable onlyAdmin {
		NewWithdraw(msg.sender, address(this).balance);
        CFO.transfer(address(this).balance);
    }
        
    function incRandNonce() external onlyContract {
        randNonce++;
    }
    
    function setDnaExist(uint64 _dna, bool _newDnaLocking) external onlyContractAdmin {
        dnaExist[_dna] = _newDnaLocking;
    }
    
    function setBonusReceived(address _add, bool _newBonusLocking) external onlyContractAdmin {
        bonusReceived[_add] = _newBonusLocking;
    }
    
    function setOwnerAtomsCount(address _owner, uint _newCount) external onlyContract {
        ownerAtomsCount[_owner] = _newCount;
    }
    
    function setAtomOwner(uint _atomId, address _owner) external onlyContract {
        atomOwner[_atomId] = _owner;
    }
        
    function pushAtom(uint64 _dna, uint8 _gen, uint8 _lev, uint8 _cool, uint32 _sons, uint64 _fathId, uint64 _mothId, uint128 _isRent, uint128 _isBuy, uint32 _isReady) external onlyContract returns (uint id) {
        Atom memory newAtom = Atom(_dna, _gen, _lev, _cool, _sons, _fathId, _mothId, _isRent, _isBuy, _isReady);
        id = atoms.push(newAtom) -1;
    }
	
	function setAtomDna(uint _atomId, uint64 _dna) external onlyAdmin {
        atoms[_atomId].dna = _dna;
    }
	
	function setAtomGen(uint _atomId, uint8 _gen) external onlyAdmin {
        atoms[_atomId].gen = _gen;
    }
    
    function setAtomLev(uint _atomId, uint8 _lev) external onlyContract {
        atoms[_atomId].lev = _lev;
    }
    
    function setAtomCool(uint _atomId, uint8 _cool) external onlyContract {
        atoms[_atomId].cool = _cool;
    }
    
    function setAtomSons(uint _atomId, uint32 _sons) external onlyContract {
        atoms[_atomId].sons = _sons;
    }
    
    function setAtomFath(uint _atomId, uint64 _fath) external onlyContract {
        atoms[_atomId].fath = _fath;
    }
    
    function setAtomMoth(uint _atomId, uint64 _moth) external onlyContract {
        atoms[_atomId].moth = _moth;
    }
    
    function setAtomIsRent(uint _atomId, uint128 _isRent) external onlyContract {
        atoms[_atomId].isRent = _isRent;
    }
    
    function setAtomIsBuy(uint _atomId, uint128 _isBuy) external onlyContract {
        atoms[_atomId].isBuy = _isBuy;
    }
    
    function setAtomIsReady(uint _atomId, uint32 _isReady) external onlyContractAdmin {
        atoms[_atomId].isReady = _isReady;
    }
    
     
    
    mapping (uint => address) tokenApprovals;
    
    function totalSupply() public view returns (uint256 total){
  	    return atoms.length;
  	}
  	
  	function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerAtomsCount[_owner];
    }
    
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        return atomOwner[_tokenId];
    }
      
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        atoms[_tokenId].isBuy  = 0;
        atoms[_tokenId].isRent = 0;
        ownerAtomsCount[_to]++;
        ownerAtomsCount[_from]--;
        atomOwner[_tokenId] = _to;
        Transfer(_from, _to, _tokenId);
    }
  
    function transfer(address _to, uint256 _tokenId) public {
        require(msg.sender == atomOwner[_tokenId]);
        _transfer(msg.sender, _to, _tokenId);
    }
    
    function approve(address _to, uint256 _tokenId) public {
        require(msg.sender == atomOwner[_tokenId]);
        tokenApprovals[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }
    
    function takeOwnership(uint256 _tokenId) public {
        require(tokenApprovals[_tokenId] == msg.sender);
        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }
    
}

contract Ownable {
    
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
}

interface ERC721Metadata {
    function name() external view returns (string _name);
    function symbol() external view returns (string _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string);
}

interface ERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}
          
contract CryptoAtomsToken is Ownable {
    
    address public CaDataAddress = 0x9b3554E6FC4F81531F6D43b611258bd1058ef6D5;
    CaData public CaDataContract = CaData(CaDataAddress);

    function kill() external
	{
	    require(msg.sender == CaDataContract.COO());
		selfdestruct(msg.sender);
	}
    
    function() public payable{}
    
    function withdrawBalance() public payable {
        require(msg.sender == CaDataContract.COO() || msg.sender == CaDataContract.CTO() || msg.sender == CaDataContract.CFO());
        CaDataContract.CFO().transfer(address(this).balance);
    }
    
    mapping (address => bool) transferEmittables;
    
    function setTransferEmittables(address _addr, bool _bool) external {
        require(msg.sender == CaDataContract.COO() || msg.sender == CaDataContract.CTO() || msg.sender == CaDataContract.CFO());
        transferEmittables[_addr] = _bool;
    }
    
    function emitTransfer(address _from, address _to, uint256 _tokenId) external{
        require(transferEmittables[msg.sender]);
        Transfer(_from, _to, _tokenId);
    }
    
     
    
        event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
        event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
        event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    
        mapping (uint => address) tokenApprovals;
        mapping (uint => address) tokenOperators;
        mapping (address => mapping (address => bool)) ownerOperators;
    
        function _transfer(address _from, address _to, uint256 _tokenId) private {
            CaDataContract.setAtomIsBuy(_tokenId,0);
            CaDataContract.setAtomIsRent(_tokenId,0);
            CaDataContract.setOwnerAtomsCount(_to,CaDataContract.ownerAtomsCount(_to)+1);
            CaDataContract.setOwnerAtomsCount(_from,CaDataContract.ownerAtomsCount(_from)-1);
            CaDataContract.setAtomOwner(_tokenId,_to);
            Transfer(_from, _to, _tokenId);
        }
        
        function _isContract(address _addr) private returns (bool check) {
            uint size;
            assembly { size := extcodesize(_addr) }
            return size > 0;
        }
        
      	function balanceOf(address _owner) external view returns (uint256 balance) {
            return CaDataContract.balanceOf(_owner);
        }
    
        function ownerOf(uint256 _tokenId) external view returns (address owner) {
            return CaDataContract.ownerOf(_tokenId);
        }
        
         
         
         
         
         
         
         
         
         
         
         
         
        function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external payable{
            require(msg.sender == CaDataContract.ownerOf(_tokenId) || ownerOperators[CaDataContract.atomOwner(_tokenId)][msg.sender] == true || msg.sender == tokenApprovals[_tokenId]);
            require(_from == CaDataContract.ownerOf(_tokenId) && _to != 0x0);
            require(_tokenId < totalSupply());
            _transfer(_from, _to, _tokenId);
            if(_isContract(_to))
            {
                require(ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) == ERC721_RECEIVED);
            }
        }
    
         
         
         
         
         
         
        function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable{
            require(msg.sender == CaDataContract.ownerOf(_tokenId) || ownerOperators[CaDataContract.atomOwner(_tokenId)][msg.sender] == true || msg.sender == tokenApprovals[_tokenId]);
            require(_from == CaDataContract.ownerOf(_tokenId) && _to != 0x0);
            require(_tokenId < totalSupply());
            _transfer(_from, _to, _tokenId);
            if(_isContract(_to))
            {
                require(ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, "") == ERC721_RECEIVED);
            }
        }
        
        
         
         
         
         
         
         
         
         
         
         
        function transferFrom(address _from, address _to, uint256 _tokenId) external payable{
            require(msg.sender == CaDataContract.ownerOf(_tokenId) || ownerOperators[CaDataContract.atomOwner(_tokenId)][msg.sender] == true || msg.sender == tokenApprovals[_tokenId]);
            require(_from == CaDataContract.ownerOf(_tokenId) && _to != 0x0);
            require(_tokenId < totalSupply());
            _transfer(_from, _to, _tokenId);
        }
        
        
         
         
         
         
         
         
        function approve(address _approved, uint256 _tokenId) external payable {
            require(msg.sender == CaDataContract.atomOwner(_tokenId) || ownerOperators[CaDataContract.atomOwner(_tokenId)][msg.sender]);
            tokenApprovals[_tokenId] = _approved;
            Approval(CaDataContract.atomOwner(_tokenId), _approved, _tokenId);
        }
        
         
         
         
         
         
         
        function setApprovalForAll(address _operator, bool _approved) external {
            ownerOperators[msg.sender][_operator] = _approved;
            ApprovalForAll(msg.sender, _operator, _approved);
        }
    
         
         
         
         
        function getApproved(uint256 _tokenId) external view returns (address) {
            return tokenApprovals[_tokenId];
        }
    
         
         
         
         
        function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
            return ownerOperators[_owner][_operator];
        }
    
     

        bytes4 constant Sign_ERC165 =
            bytes4(keccak256('supportsInterface(bytes4)'));
        
        bytes4 constant Sign_ERC721 =
            bytes4(keccak256('balanceOf(address)')) ^
            bytes4(keccak256('ownerOf(uint256)')) ^
            bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) ^
            bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
            bytes4(keccak256('transferFrom(address,address,uint256)')) ^
            bytes4(keccak256('approve(address,uint256)')) ^
            bytes4(keccak256('setApprovalForAll(address,bool)')) ^
            bytes4(keccak256('getApproved(uint256)')) ^
            bytes4(keccak256('isApprovedForAll(address,address)'));
            
        function supportsInterface(bytes4 interfaceID) external view returns (bool)
        {
            return ((interfaceID == Sign_ERC165) || (interfaceID == Sign_ERC721));
        }
    
     
    
         
         
         
         
         
         
         
         
         
         
         
        
        bytes4 constant ERC721_RECEIVED = bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        
        function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4){
            return ERC721_RECEIVED;
        }
    
     
    
        string baseUri = "https://www.cryptoatoms.org/cres/uri/";
    
        function name() external view returns (string _name) {
            return "Atom";
        }
    
        function symbol() external view returns (string _symbol){
            return "ATH";
        }
    
         
         
         
         
        function tokenURI(uint256 _tokenId) external view returns (string){
            require(_tokenId < totalSupply());
            uint256 uid;
            bytes32 bid;
            uid = _tokenId;
            if (uid == 0) 
            {
                bid = '0';
            }
            else 
            {
                while (uid > 0) 
                {
                    bid = bytes32(uint(bid) / (2 ** 8));
                    bid |= bytes32(((uid % 10) + 48) * 2 ** (8 * 31));
                    uid /= 10;
                }
            }
            return string(abi.encodePacked(baseUri, bid));
        }
        
        function setBaseUri (string _newBaseUri) external {
            require(msg.sender == CaDataContract.COO() || msg.sender == CaDataContract.CTO() || msg.sender == CaDataContract.CFO());
            baseUri = _newBaseUri;
        }
    
     
        
        function totalSupply() public view returns (uint256 total){
      	    return CaDataContract.totalSupply();
      	}
      	   
      	 
         
         
         
         
        function tokenByIndex(uint256 _index) external view returns (uint256){
            require(_index < totalSupply());
            return _index;
        }
    
         
         
         
         
         
         
         
        function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256){
            require(_index < CaDataContract.balanceOf(_owner));
            uint64 counter = 0;
            for (uint64 i = 0; i < CaDataContract.totalSupply(); i++)
            {
                if (CaDataContract.atomOwner(i) == _owner) {
                    if(counter == _index)
                    {
                        uint256 result = i;
                        i = uint64(CaDataContract.totalSupply());
                    }
                    else
                    {
                        counter++;
                    }
                }
            }
            return result;
        }
    
    
     
        
        function decimals() external view returns (uint8 _decimals){
            return 0;
        }
        
        function implementsERC721() public pure returns (bool){
            return true;
        }
        
}
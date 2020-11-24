 

pragma solidity ^0.4.18;
pragma solidity ^0.4.18;

 
 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract Beneficiary is Ownable {

    address public beneficiary;

    function setBeneficiary(address _beneficiary) onlyOwner public {
        beneficiary = _beneficiary;
    }


}


contract Pausable is Beneficiary{
    bool public paused = false;

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyOwner whenNotPaused {
        paused = true;
    }

    function unpause() public onlyOwner whenPaused {
         
        paused = false;
    }
} 

library SafeMath {

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


contract WarshipAccess is Pausable{
	address[] public OfficialApps;
	 

	function AddOfficialApps(address _app) onlyOwner public{
		require(_app != address(0));
		OfficialApps.push(_app);
	}
	
	function nukeApps()onlyOwner public{
	    for(uint i = 0; i < OfficialApps.length; i++){
			delete OfficialApps[i];
	        
	    }
	}

	function _isOfficialApps(address _app) internal view returns (bool){
		for(uint i = 0; i < OfficialApps.length; i++){
			if( _app == OfficialApps[i] ){
				return true;
			}
		}
		return false;
	}

	modifier OnlyOfficialApps {
        require(_isOfficialApps(msg.sender));
        _;
    }



}




 

contract WarshipMain is WarshipAccess{
    
    using SafeMath for uint256;

    struct Warship {
        uint128 appearance;  
        uint32 profile; 
        uint8 firepower;
        uint8 armor;
        uint8 hitrate;
        uint8 speed;
        uint8 duration; 
        uint8 shiptype; 
        uint8 level; 
        uint8 status; 
        uint16 specials; 
        uint16 extend;
    } 

    Warship[] public Ships;
    mapping (uint256 => address) public ShipIdToOwner;
     
    mapping (address => uint256) OwnerShipCount;
     
    mapping (uint256 => address) public ShipIdToApproval;
     
    mapping (uint256 => uint256) public ShipIdToStatus;
     
     
    

     
    address public SaleAuction;
    function setSaleAuction(address _sale) onlyOwner public{
        require(_sale != address(0));
        SaleAuction = _sale;
    }



     
    event NewShip(address indexed owner, uint indexed shipId, uint256 wsic);
    event ShipStatusUpdate(uint indexed shipId, uint8 newStatus);
    event ShipStructUpdate(uint indexed shipId, uint256 wsic);

     
    bool public implementsERC721 = true;
    string public constant name = "EtherWarship";
    string public constant symbol = "SHIP";
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); 
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    function balanceOf(address _owner) public view returns (uint256 _balance){
        return OwnerShipCount[_owner];
    }
    function ownerOf(uint256 _tokenId) public view returns (address _owner){
        return ShipIdToOwner[_tokenId];
    }
     
     
     
     


    

     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ShipIdToOwner[_tokenId] == _claimant;
    }
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ShipIdToApproval[_tokenId] == _claimant;
    }


     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        OwnerShipCount[_to]=OwnerShipCount[_to].add(1);
        ShipIdToOwner[_tokenId] = _to;
        if (_from != address(0)) {
            OwnerShipCount[_from]=OwnerShipCount[_from].sub(1);
             
            delete ShipIdToApproval[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        ShipIdToApproval[_tokenId] = _approved;
    }

     
    function transfer(address _to, uint256 _tokenId) external whenNotPaused {
         
        require(_to != address(0));
         
        require(_to != address(this));
         
        require(_owns(msg.sender, _tokenId));
         
        require(ShipIdToStatus[_tokenId]==1||msg.sender==SaleAuction);
         

        if(msg.sender == SaleAuction){
            ShipIdToStatus[_tokenId] = 1;
        }

        _transfer(msg.sender, _to, _tokenId);

    }

     
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
         
        require(_owns(msg.sender, _tokenId));
         
        _approve(_tokenId, _to);
         
        Approval(msg.sender, _to, _tokenId);
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused {
         
        require(_to != address(0));
         
        require(_to != address(this));
         
         
        require(_approvedFor(msg.sender, _tokenId)||msg.sender==SaleAuction); 

        require(_owns(_from, _tokenId));

        require(ShipIdToStatus[_tokenId]==1);
         

        if(msg.sender == SaleAuction){
            ShipIdToStatus[_tokenId] = 4;
        }


         
        _transfer(_from, _to, _tokenId);
    }
     
    function totalSupply() public view returns (uint) {
        return Ships.length;
    }

     
    function takeOwnership(uint256 _tokenId) public {
         
        require(ShipIdToApproval[_tokenId] == msg.sender);

        require(ShipIdToStatus[_tokenId]==1);
         

        _transfer(ownerOf(_tokenId), msg.sender, _tokenId);
    }


     





     
    function _translateWSIC (uint256 _wsic) internal pure returns(Warship){
   
   
   
         
         
         
         
         
         
         
         
         
        Warship memory  _ship = Warship(uint128(_wsic >> 128), uint32((_wsic>>96)&0xffffffff), uint8((_wsic>>88)&0xff), uint8((_wsic>>80)&0xff), uint8((_wsic>>72)&0xff), uint8((_wsic>>64)&0xff),
         uint8((_wsic>>56)&0xff), uint8((_wsic>>48)&0xff), uint8((_wsic>>40)&0xff), uint8((_wsic>>32)&0xff),  uint16((_wsic>>16)&0xffff), uint16(_wsic&0xffff));
        return _ship;
    }
    function _encodeWSIC(Warship _ship) internal pure returns(uint256){
        uint256 _wsic = 0x00;
        _wsic = _wsic ^ (uint256(_ship.appearance) << 128);
        _wsic = _wsic ^ (uint256(_ship.profile) << 96);
        _wsic = _wsic ^ (uint256(_ship.firepower) << 88);
        _wsic = _wsic ^ (uint256(_ship.armor) << 80);
        _wsic = _wsic ^ (uint256(_ship.hitrate) << 72);
        _wsic = _wsic ^ (uint256(_ship.speed) << 64);
        _wsic = _wsic ^ (uint256(_ship.duration) << 56);
        _wsic = _wsic ^ (uint256(_ship.shiptype) << 48);
        _wsic = _wsic ^ (uint256(_ship.level) << 40);
        _wsic = _wsic ^ (uint256(_ship.status) << 32);
        _wsic = _wsic ^ (uint256(_ship.specials) << 16);
        _wsic = _wsic ^ (uint256(_ship.extend));
        return _wsic;
    }


    

     
     
     
    function _createship (uint256 _wsic, address _owner) internal returns(uint){
         
        Warship memory _warship = _translateWSIC(_wsic);
         
        uint256 newshipId = Ships.push(_warship) - 1;
         
        NewShip(_owner, newshipId, _wsic);
         
        ShipIdToStatus[newshipId] = 1;
         
        _transfer(0, _owner, newshipId);
         
       
        

        return newshipId; 
    }

     
    function _update (uint256 _wsic, uint256 _tokenId) internal returns(bool){
         
        require(_tokenId <= totalSupply());
         
        Warship memory _warship = _translateWSIC(_wsic);
         
        ShipStructUpdate(_tokenId, _wsic);
         
        Ships[_tokenId] = _warship;

        return true;
    }


     
    function createship(uint256 _wsic, address _owner) external OnlyOfficialApps returns(uint){
         
        require(_owner != address(0));
        return _createship(_wsic, _owner);
    }

     
    function updateship (uint256 _wsic, uint256 _tokenId) external OnlyOfficialApps returns(bool){
        return _update(_wsic, _tokenId);
    }
     
    function SetStatus(uint256 _tokenId, uint256 _status) external OnlyOfficialApps returns(bool){
        require(uint8(_status)==_status);
        ShipIdToStatus[_tokenId] = _status;
        ShipStatusUpdate(_tokenId, uint8(_status));
        return true;
    }






     
    function Getwsic(uint256 _tokenId) external view returns(uint256){
         
        require(_tokenId < Ships.length);
        uint256 _wsic = _encodeWSIC(Ships[_tokenId]);
        return _wsic;
    }

     
    function GetShipsByOwner(address _owner) external view returns(uint[]) {
    uint[] memory result = new uint[](OwnerShipCount[_owner]);
    uint counter = 0;
    for (uint i = 0; i < Ships.length; i++) {
          if (ShipIdToOwner[i] == _owner) {
            result[counter] = i;
            counter++;
          }
        }
    return result;
    }

     
    function GetStatus(uint256 _tokenId) external view returns(uint){
        return ShipIdToStatus[_tokenId];
    }



}
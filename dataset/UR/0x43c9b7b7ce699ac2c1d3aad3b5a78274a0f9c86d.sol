 

 
contract ERC721Basic {
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;


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

 

 
library AddressUtils {

   
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
     
     
     
     
     
     
        assembly { size := extcodesize(addr) }   
        return size > 0;
    }

}

 

 


contract acl{

    enum Role {
        USER,
        ORACLE,
        ADMIN
    }

    mapping (address=> Role) permissions;

    constructor() public {
        permissions[msg.sender] = Role(2);
    }

    function setRole(uint8 rolevalue,address entity)external check(2){
        permissions[entity] = Role(rolevalue);
    }

    function getRole(address entity)public view returns(Role){
        return permissions[entity];
    }

    modifier check(uint8 role) {
        require(uint8(getRole(msg.sender)) == role);
        _;
    }
}

 

 
contract ERC721BasicToken is ERC721Basic, acl {
    using SafeMath for uint256;
    using AddressUtils for address;

    uint public numTokensTotal;

   
    mapping (uint256 => address) internal tokenOwner;

   
    mapping (uint256 => address) internal tokenApprovals;

   
    mapping (address => uint256) internal ownedTokensCount;

   
    mapping (address => mapping (address => bool)) internal operatorApprovals;

   
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

   
    modifier canTransfer(uint256 _tokenId) {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

   
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

   
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
      
        return owner;
    }

   
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

   
    function approve(address _to, uint256 _tokenId) public {
        address owner = tokenOwner[_tokenId];

        tokenApprovals[_tokenId] = _to;

        require(_to != ownerOf(_tokenId));
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

   
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

   
    function setApprovalForAll(address _to, bool _approved) public {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return operatorApprovals[_owner][_operator];
    }

   
    function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }



   
    function isApprovedOrOwner(address _spender, uint256 _tokenId) public view returns (bool) {
        address owner = ownerOf(_tokenId);
        return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
    }

   
    function _mint(address _to, uint256 _tokenId) external check(2) {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        numTokensTotal = numTokensTotal.add(1);
        emit Transfer(address(0), _to, _tokenId);
    }

   
    function _burn(address _owner, uint256 _tokenId) external check(2) {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        numTokensTotal = numTokensTotal.sub(1);
        emit Transfer(_owner, address(0), _tokenId);
    }

   
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
            emit Approval(_owner, address(0), _tokenId);
        }
    }

   
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

   
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }
}

 

contract testreg is ERC721BasicToken  {

	 

    struct TokenStruct {
        string token_uri;
    }

    mapping (uint256 => TokenStruct) TokenId;

}

 

contract update is testreg {

    event UpdateToken(uint256 _tokenId, string new_uri);

    function updatetoken(uint256 _tokenId, string new_uri) external check(1){
        TokenId[_tokenId].token_uri = new_uri;

        emit UpdateToken(_tokenId, new_uri);
    }

    function _mint_with_uri(address _to, uint256 _tokenId, string new_uri) external check(2) {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        numTokensTotal = numTokensTotal.add(1);
        TokenId[_tokenId].token_uri = new_uri;
        emit Transfer(address(0), _to, _tokenId);
    }
}

 

 

contract bloomingPool is update {

    using SafeMath for uint256;

    uint256 public totalShares = 0;
    uint256 public totalReleased = 0;
    bool public freeze;

    mapping(address => uint256) public shares;

    constructor() public {
        freeze = false;
    }

    function() public payable { }


    function calculate_total_shares(uint256 _shares,uint256 unique_id )internal{
        shares[tokenOwner[unique_id]] = shares[tokenOwner[unique_id]].add(_shares);
        totalShares = totalShares.add(_shares);
    }

    function oracle_call(uint256 unique_id) external check(1){
        calculate_total_shares(1,unique_id);
    }

    function get_shares() external view returns(uint256 individual_shares){
        return shares[msg.sender];
    }

    function freeze_pool(bool _freeze) external check(2){
        freeze = _freeze;
    }

    function reset_individual_shares(address payee)internal {
        shares[payee] = 0;
    }

    function substract_individual_shares(uint256 _shares)internal {
        totalShares = totalShares - _shares;
    }

    function claim()public{
        payout(msg.sender);
    }

    function payout(address to) internal returns(bool){
        require(freeze == false);
        address payee = to;
        require(shares[payee] > 0);

        uint256 volume = address(this).balance;
        uint256 payment = volume.mul(shares[payee]).div(totalShares);

        require(payment != 0);
        require(address(this).balance >= payment);

        totalReleased = totalReleased.add(payment);
        payee.transfer(payment);
        substract_individual_shares(shares[payee]);
        reset_individual_shares(payee);
    }

    function emergency_withdraw(uint amount) external check(2) {
        require(amount <= this.balance);
        msg.sender.transfer(amount);
    }

}

 

contract buyable is bloomingPool {

    address INFRASTRUCTURE_POOL_ADDRESS;
    mapping (uint256 => uint256) TokenIdtosetprice;
    mapping (uint256 => uint256) TokenIdtoprice;

    event Set_price_and_sell(uint256 tokenId, uint256 Price);
    event Stop_sell(uint256 tokenId);

    constructor() public {}

    function initialisation(address _infrastructure_address) public check(2){
        INFRASTRUCTURE_POOL_ADDRESS = _infrastructure_address;
    }

    function set_price_and_sell(uint256 UniqueID,uint256 Price) external {
        approve(address(this), UniqueID);
        TokenIdtosetprice[UniqueID] = Price;
        emit Set_price_and_sell(UniqueID, Price);
    }

    function stop_sell(uint256 UniqueID) external payable{
        require(tokenOwner[UniqueID] == msg.sender);
        clearApproval(tokenOwner[UniqueID],UniqueID);
        emit Stop_sell(UniqueID);
    }

    function buy(uint256 UniqueID) external payable {
        address _to = msg.sender;
        require(TokenIdtosetprice[UniqueID] == msg.value);
        TokenIdtoprice[UniqueID] = msg.value;
        uint _blooming = msg.value.div(20);
        uint _infrastructure = msg.value.div(20);
        uint _combined = _blooming.add(_infrastructure);
        uint _amount_for_seller = msg.value.sub(_combined);
        require(tokenOwner[UniqueID].call.gas(99999).value(_amount_for_seller)());
        this.transferFrom(tokenOwner[UniqueID], _to, UniqueID);
        if(!INFRASTRUCTURE_POOL_ADDRESS.call.gas(99999).value(_infrastructure)()){
            revert("transfer to infrastructurePool failed");
		}
    }

    function get_token_data(uint256 _tokenId) external view returns(uint256 _price, uint256 _setprice, bool _buyable){
        _price = TokenIdtoprice[_tokenId];
        _setprice = TokenIdtosetprice[_tokenId];
        if (tokenApprovals[_tokenId] != address(0)){
            _buyable = true;
        }
    }

    function get_token_data_buyable(uint256 _tokenId) external view returns(bool _buyable) {
        if (tokenApprovals[_tokenId] != address(0)){
            _buyable = true;
        }
    }

    function get_all_sellable_token()external view returns(bool[101] list_of_available){
        uint i;
        for(i = 0;i<101;i++) {
            if (tokenApprovals[i] != address(0)){
                list_of_available[i] = true;
          }else{
                list_of_available[i] = false;
          }
        }
    }
    function get_my_tokens()external view returns(bool[101] list_of_my_tokens){
        uint i;
        address _owner = msg.sender;
        for(i = 0;i<101;i++) {
            if (tokenOwner[i] == _owner){
                list_of_my_tokens[i] = true;
          }else{
                list_of_my_tokens[i] = false;
          }
        }
    }

}
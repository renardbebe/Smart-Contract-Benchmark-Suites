 

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  address private _owner;

  constructor () internal {
    _owner = msg.sender;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner(), "UserWallet: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "UserWallet: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract ERC20Basic {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferOwnership(address newOwner) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract UserWallet is Ownable{

  event TokenWithdraw(address from, address to, uint256 amount);
  event TokenSweep(address to, uint256 amount);

  ERC20Basic private _token;

  constructor (ERC20Basic token) public {
    require(address(token) != address(0), 'UserWallet: token is the zero address');
    _token = token;
  }

  function balanceOfToken() public view returns (uint256) {
    return _balanceOfToken();
  }

  function _balanceOfToken() private view returns (uint256) {
    return _token.balanceOf(address(this));
  }

  function withdrawToken(address receiver, uint256 tokenAmount) public onlyOwner {
    _withdrawToken(receiver, tokenAmount);
  }

  function _withdrawToken(address receiver, uint256 tokenAmount) private onlyOwner {
    require(receiver != address(0), 'UserWallet: require set receiver address, receiver is the zero address.');
    require(tokenAmount > 0, "UserWallet: tokenAmount is 0");
    require(_balanceOfToken() >= tokenAmount, "UserWallet: not enough token amount");
    require(_token.transfer(receiver, tokenAmount));
    emit TokenWithdraw(address(this), receiver, tokenAmount);
  }

  function sweep(address receiver) public onlyOwner {
    require(receiver != address(0), 'UserWallet: require set receiver address, receiver is the zero address.');
    require(_token.transfer(receiver, _balanceOfToken()));
    emit TokenSweep(receiver, _balanceOfToken());
  }

  function setNewOwner(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
    _token.transferOwnership(newOwner);
  }
}

contract GotchuWallet is Ownable{
  string private _version = '0.1.0';

  function generateUserWallet() public onlyOwner {
     
    address token = 0xAE31b85Bfe62747d0836B82608B4830361a3d37a;

    UserWallet userWallet = new UserWallet(ERC20Basic(token));

    userWallet.setNewOwner(0xD4F78DA8bA2538164aa5F42e0c1B7409Ed5206ec);
  }

  function version() public view returns (string memory){
    return _version;
  }
}
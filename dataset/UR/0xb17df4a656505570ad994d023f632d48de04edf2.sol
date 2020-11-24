 

pragma solidity >=0.5.0 <0.6.0;

interface INMR {

     

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

     

     
    function withdraw(address _from, address _to, uint256 _value) external returns(bool ok);

     
    function destroyStake(address _staker, bytes32 _tag, uint256 _tournamentID, uint256 _roundID) external returns (bool ok);

     
    function createRound(uint256, uint256, uint256, uint256) external returns (bool ok);

     
    function createTournament(uint256 _newDelegate) external returns (bool ok);

     
    function mint(uint256 _value) external returns (bool ok);

     
    function numeraiTransfer(address _to, uint256 _value) external returns (bool ok);

     
    function contractUpgradable() external view returns (bool);

    function getTournament(uint256 _tournamentID) external view returns (uint256, uint256[] memory);

    function getRound(uint256 _tournamentID, uint256 _roundID) external view returns (uint256, uint256, uint256);

    function getStake(uint256 _tournamentID, uint256 _roundID, address _staker, bytes32 _tag) external view returns (uint256, uint256, bool, bool);

}



 
contract Initializable {

   
  bool private initialized;

   
  bool private initializing;

   
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

   
  function isConstructor() private view returns (bool) {
     
     
     
     
     
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

   
  uint256[50] private ______gap;
}


 
contract Ownable is Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function initialize(address sender) public initializer {
        _owner = sender;
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

    uint256[50] private ______gap;
}



contract Manageable is Initializable, Ownable {
    address private _manager;

    event ManagementTransferred(address indexed previousManager, address indexed newManager);

     
    function initialize(address sender) initializer public {
        Ownable.initialize(sender);
        _manager = sender;
        emit ManagementTransferred(address(0), _manager);
    }

     
    function manager() public view returns (address) {
        return _manager;
    }

     
    modifier onlyManagerOrOwner() {
        require(isManagerOrOwner());
        _;
    }

     
    function isManagerOrOwner() public view returns (bool) {
        return (msg.sender == _manager || isOwner());
    }

     
    function transferManagement(address newManager) public onlyOwner {
        require(newManager != address(0));
        emit ManagementTransferred(_manager, newManager);
        _manager = newManager;
    }

    uint256[50] private ______gap;
}



contract Relay is Manageable {

    bool public active = true;
    bool private _upgraded;

     
    address private constant _TOKEN = address(
        0x1776e1F26f98b1A5dF9cD347953a26dd3Cb46671
    );
    address private constant _ONE_MILLION_ADDRESS = address(
        0x00000000000000000000000000000000000F4240
    );    
    address private constant _NULL_ADDRESS = address(
        0x0000000000000000000000000000000000000000
    );
    address private constant _BURN_ADDRESS = address(
        0x000000000000000000000000000000000000dEaD
    );

     
    modifier isUser(address _user) {
        require(
            _user <= _ONE_MILLION_ADDRESS
            && _user != _NULL_ADDRESS
            && _user != _BURN_ADDRESS
            , "_from must be a user account managed by Numerai"
        );
        _;
    }

     
    modifier onlyActive() {
        require(active, "User account relay has been disabled");
        _;
    }

     
     
    constructor(address _owner) public {
        require(
            address(this) == address(0xB17dF4a656505570aD994D023F632D48De04eDF2),
            "incorrect deployment address - check submitting account & nonce."
        );

        Manageable.initialize(_owner);
    }

     
     
     
     
     
     
    function withdraw(address _from, address _to, uint256 _value) public onlyManagerOrOwner onlyActive isUser(_from) returns (bool ok) {
        require(INMR(_TOKEN).withdraw(_from, _to, _value));
        return true;
    }

     
    function burnZeroAddress() public {
        uint256 amtZero = INMR(_TOKEN).balanceOf(_NULL_ADDRESS);
        uint256 amtBurn = INMR(_TOKEN).balanceOf(_BURN_ADDRESS);
        require(INMR(_TOKEN).withdraw(_NULL_ADDRESS, address(this), amtZero));
        require(INMR(_TOKEN).withdraw(_BURN_ADDRESS, address(this), amtBurn));
        uint256 amtThis = INMR(_TOKEN).balanceOf(address(this));
        _burn(amtThis);
    }

     
     
    function disable() public onlyOwner onlyActive {
        active = false;
    }

     
     
    function disableTokenUpgradability() public onlyOwner onlyActive {
        require(INMR(_TOKEN).createRound(uint256(0),uint256(0),uint256(0),uint256(0)));
    }

     
     
     
    function changeTokenDelegate(address _newDelegate) public onlyOwner onlyActive {
        require(INMR(_TOKEN).createTournament(uint256(_newDelegate)));
    }

     
     
    function token() external pure returns (address) {
        return _TOKEN;
    }

     
     
     
     
    function _burn(uint256 _value) internal {
        if (INMR(_TOKEN).contractUpgradable()) {
            require(INMR(_TOKEN).transfer(address(0), _value));
        } else {
            require(INMR(_TOKEN).mint(_value), "burn not successful");
        }
    }
}
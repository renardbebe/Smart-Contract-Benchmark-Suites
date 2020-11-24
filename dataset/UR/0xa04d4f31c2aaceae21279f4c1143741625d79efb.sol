 

 

pragma solidity ^0.4.24;


 
contract ERC20 {

     
    function totalSupply() public view returns (uint256 supply);

     
    function balanceOf(address _owner) public view returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 


interface IGivethBridge {
    function donate(uint64 giverId, uint64 receiverId) external payable;
    function donate(uint64 giverId, uint64 receiverId, address token, uint _amount) external payable;
}

interface IFundsForwarderFactory {
    function bridge() external returns (address);
    function escapeHatchCaller() external returns (address);
    function escapeHatchDestination() external returns (address);
}

interface IMolochDao {
    function approvedToken() external returns (address);
    function members(address member) external returns (address, uint256, bool, uint256);
    function ragequit(uint sharesToBurn) external;
}

interface IWEth {
    function withdraw(uint wad) external;
    function balanceOf(address guy) external returns (uint);
}


contract FundsForwarder {
    uint64 public receiverId;
    uint64 public giverId;
    IFundsForwarderFactory public fundsForwarderFactory;

    string private constant ERROR_ERC20_APPROVE = "ERROR_ERC20_APPROVE";
    string private constant ERROR_BRIDGE_CALL = "ERROR_BRIDGE_CALL";
    string private constant ERROR_ZERO_BRIDGE = "ERROR_ZERO_BRIDGE";
    string private constant ERROR_DISALLOWED = "RECOVER_DISALLOWED";
    string private constant ERROR_TOKEN_TRANSFER = "RECOVER_TOKEN_TRANSFER";
    string private constant ERROR_ALREADY_INITIALIZED = "INIT_ALREADY_INITIALIZED";
    uint private constant MAX_UINT = uint(-1);

    event Forwarded(address to, address token, uint balance);
    event EscapeHatchCalled(address token, uint amount);

    constructor() public {
         
         
         
        fundsForwarderFactory = IFundsForwarderFactory(address(-1));
    }

     
    function() public payable {}

     
    function initialize(uint64 _giverId, uint64 _receiverId) public {
         
        require(fundsForwarderFactory == address(0), ERROR_ALREADY_INITIALIZED);
         
        fundsForwarderFactory = IFundsForwarderFactory(msg.sender);
         
        require(fundsForwarderFactory.bridge() != address(0), ERROR_ZERO_BRIDGE);

        receiverId = _receiverId;
        giverId = _giverId;
    }

     
    function forward(address _token) public {
        IGivethBridge bridge = IGivethBridge(fundsForwarderFactory.bridge());
        require(bridge != address(0), ERROR_ZERO_BRIDGE);

        uint balance;
        bool result;
         
        if (_token == address(0)) {
            balance = address(this).balance;
             
             
             
             
            result = address(bridge).call.value(balance)(
                0xbde60ac9,
                giverId,
                receiverId
            );
         
        } else {
            ERC20 token = ERC20(_token);
            balance = token.balanceOf(this);
             
             
             
             
             
             
             
            if (token.allowance(address(this), bridge) < balance) {
                require(token.approve(bridge, MAX_UINT), ERROR_ERC20_APPROVE);
            }

             
             
             
             
            result = address(bridge).call(
                0x4c4316c7,
                giverId,
                receiverId,
                token,
                balance
            );
        }
        require(result, ERROR_BRIDGE_CALL);
        emit Forwarded(bridge, _token, balance);
    }

     
    function forwardMultiple(address[] _tokens) public {
        uint tokensLength = _tokens.length;
        for (uint i = 0; i < tokensLength; i++) {
            forward(_tokens[i]);
        }
    }

     
    function forwardMoloch(address _molochDao, bool _convertWeth) public {
        IMolochDao molochDao = IMolochDao(_molochDao);
        (,uint shares,,) = molochDao.members(address(this));
        molochDao.ragequit(shares);
        address approvedToken = molochDao.approvedToken();
        if (_convertWeth) {
            IWEth weth = IWEth(approvedToken);
            weth.withdraw(weth.balanceOf(address(this)));
            forward(address(0));
        } else {
            forward(molochDao.approvedToken());
        }
    }

     
    function escapeHatch(address _token) public {
         
        require(msg.sender == fundsForwarderFactory.escapeHatchCaller(), ERROR_DISALLOWED);

        address escapeHatchDestination = fundsForwarderFactory.escapeHatchDestination();

        uint256 balance;
        if (_token == 0x0) {
            balance = address(this).balance;
            escapeHatchDestination.transfer(balance);
        } else {
            ERC20 token = ERC20(_token);
            balance = token.balanceOf(this);
            require(token.transfer(escapeHatchDestination, balance), ERROR_TOKEN_TRANSFER);
        }

        emit EscapeHatchCalled(_token, balance);
    }
}

 

 


contract IsContract {
     
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

 


 
 
 
 
 
 
 
 
 
contract Owned {

    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed by, address indexed to);
    event OwnershipTransferred(address indexed from, address indexed to);
    event OwnershipRemoved();

     
    constructor() public {
        owner = msg.sender;
    }

     
     
    modifier onlyOwner() {
        require (msg.sender == owner,"err_ownedNotOwner");
        _;
    }

     
     
     
     
     
     
    function proposeOwnership(address _newOwnerCandidate) public onlyOwner {
        newOwnerCandidate = _newOwnerCandidate;

        emit OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
     
    function acceptOwnership() public {
        require(msg.sender == newOwnerCandidate,"err_ownedNotCandidate");

        address oldOwner = owner;
        owner = newOwnerCandidate;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
    function changeOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0,"err_ownedInvalidAddress");

        address oldOwner = owner;
        owner = _newOwner;
        newOwnerCandidate = 0x0;

        emit OwnershipTransferred(oldOwner, owner);
    }

     
     
     
     
     
    function removeOwnership(address _dac) public onlyOwner {
        require(_dac == 0xdac,"err_ownedInvalidDac");

        owner = 0x0;
        newOwnerCandidate = 0x0;

        emit OwnershipRemoved();
    }
}

 


 




 
 
 
 
 
contract Escapable is Owned {
    address public escapeHatchCaller;
    address public escapeHatchDestination;
    mapping (address=>bool) private escapeBlacklist;  

     
     
     
     
     
     
     
     
     
     
    constructor(address _escapeHatchCaller, address _escapeHatchDestination) public {
        escapeHatchCaller = _escapeHatchCaller;
        escapeHatchDestination = _escapeHatchDestination;
    }

     
     
    modifier onlyEscapeHatchCallerOrOwner {
        require (
            (msg.sender == escapeHatchCaller)||(msg.sender == owner),
            "err_escapableInvalidCaller"
        );
        _;
    }

     
     
     
     
    function blacklistEscapeToken(address _token) internal {
        escapeBlacklist[_token] = true;

        emit EscapeHatchBlackistedToken(_token);
    }

     
     
     
     
    function isTokenEscapable(address _token) public view returns (bool) {
        return !escapeBlacklist[_token];
    }

     
     
     
    function escapeHatch(address _token) public onlyEscapeHatchCallerOrOwner {
        require(escapeBlacklist[_token]==false,"err_escapableBlacklistedToken");

        uint256 balance;

         
        if (_token == 0x0) {
            balance = address(this).balance;
            escapeHatchDestination.transfer(balance);
            emit EscapeHatchCalled(_token, balance);
            return;
        }
         
        ERC20 token = ERC20(_token);
        balance = token.balanceOf(this);
        require(token.transfer(escapeHatchDestination, balance),"err_escapableTransfer");
        emit EscapeHatchCalled(_token, balance);
    }

     
     
     
     
     
    function changeHatchEscapeCaller(address _newEscapeHatchCaller) public onlyEscapeHatchCallerOrOwner {
        escapeHatchCaller = _newEscapeHatchCaller;
    }

    event EscapeHatchBlackistedToken(address token);
    event EscapeHatchCalled(address token, uint amount);
}

 




contract FundsForwarderFactory is Escapable, IsContract {
    address public bridge;
    address public childImplementation;

    string private constant ERROR_NOT_A_CONTRACT = "ERROR_NOT_A_CONTRACT";
    string private constant ERROR_HATCH_CALLER = "ERROR_HATCH_CALLER";
    string private constant ERROR_HATCH_DESTINATION = "ERROR_HATCH_DESTINATION";

    event NewFundForwarder(address indexed _giver, uint64 indexed _receiverId, address fundsForwarder);
    event BridgeChanged(address newBridge);
    event ChildImplementationChanged(address newChildImplementation);

     
    constructor(
        address _bridge,
        address _escapeHatchCaller,
        address _escapeHatchDestination,
        address _childImplementation
    ) Escapable(_escapeHatchCaller, _escapeHatchDestination) public {
        require(isContract(_bridge), ERROR_NOT_A_CONTRACT);
        bridge = _bridge;

         
        Escapable bridgeInstance = Escapable(_bridge);
        require(_escapeHatchCaller == bridgeInstance.escapeHatchCaller(), ERROR_HATCH_CALLER);
        require(_escapeHatchDestination == bridgeInstance.escapeHatchDestination(), ERROR_HATCH_DESTINATION);
         
        changeOwnership(bridgeInstance.owner());

         
        if (_childImplementation == address(0)) {
            childImplementation = new FundsForwarder();
        } else {
            childImplementation = _childImplementation;
        }
    }

     
    function changeBridge(address _bridge) external onlyEscapeHatchCallerOrOwner {
        bridge = _bridge;
        emit BridgeChanged(_bridge);
    }

     
    function changeChildImplementation(address _childImplementation) external onlyEscapeHatchCallerOrOwner {
        childImplementation = _childImplementation;
        emit ChildImplementationChanged(_childImplementation);
    }

     
    function newFundsForwarder(uint64 _giverId, uint64 _receiverId) public {
        address fundsForwarder = _deployMinimal(childImplementation);
        FundsForwarder(fundsForwarder).initialize(_giverId, _receiverId);

         
        emit NewFundForwarder(_giverId, _receiverId, fundsForwarder);
    }

     
    function _deployMinimal(address _logic) internal returns (address proxy) {
         
        bytes20 targetBytes = bytes20(_logic);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            proxy := create(0, clone, 0x37)
        }
    }
}
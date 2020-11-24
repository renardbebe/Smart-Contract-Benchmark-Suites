 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;


interface IEscrow {
    function balance() external returns (uint);
    function send(address payable addr, uint amt) external returns (bool);
}

 

pragma solidity ^0.5.0;




 
contract Escrow is IEscrow {

    address public escrowLibrary;

    modifier onlyLibrary() {
        require(msg.sender == escrowLibrary, "Only callable by library contract");
        _;
    }

    constructor(address _escrowLibrary) internal {
        escrowLibrary = _escrowLibrary;
    }
}


 
contract EthEscrow is Escrow {

    constructor(address escrowLibrary) public Escrow(escrowLibrary) {}

    function send(address payable addr, uint amt) public onlyLibrary returns (bool) {
        return addr.send(amt);
    }

    function balance() public returns (uint) {
        return address(this).balance;
    }
}

 

pragma solidity ^0.5.0;

 
library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
         
        if (signature.length != 65) {
            return (address(0));
        }

         
        bytes32 r;
        bytes32 s;
        uint8 v;

         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
         
         
         
         
         
         
         
         
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

         
        return ecrecover(hash, v, r, s);
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

pragma solidity ^0.5.0;





 
contract EscrowLibrary {

    using SafeMath for uint;

    string constant SIGNATURE_PREFIX = '\x19Ethereum Signed Message:\n';
    uint constant FORCE_REFUND_TIME = 2 days;

     
    enum EscrowState {
        None,
        Unfunded,
        Open,
        PuzzlePosted,
        Closed
    }

     
    enum MessageTypeId {
        None,
        Cashout,
        Puzzle,
        Refund
    }

     
    enum EscrowCloseReason {
        Refund,
        PuzzleRefund,
        PuzzleSolve,
        Cashout,
        ForceRefund
    }

    event PuzzlePosted(address indexed escrow, bytes32 puzzleSighash);
    event Preimage(address indexed escrow, bytes32 preimage, bytes32 puzzleSighash);
    event EscrowClosed(address indexed escrow, EscrowCloseReason reason, bytes32 closingSighash);
    event FundsTransferred(address indexed escrow, address reserveAddress);

    struct EscrowParams {
         
        uint escrowAmount;

         
        uint escrowTimelock;

         
        address payable escrowerReserve;
        address escrowerTrade;
        address escrowerRefund;

         
        address payable payeeReserve;
        address payeeTrade;

         
        EscrowState escrowState;

         
        uint escrowerBalance;
        uint payeeBalance;
    }

     
    struct PuzzleParams {
         
        uint tradeAmount;

         
        bytes32 puzzle;

         
        uint puzzleTimelock;

         
        bytes32 puzzleSighash;
    }

     
    address public escrowFactory;

     
    mapping(address => EscrowParams) public escrows;

     
     
    mapping(address => PuzzleParams) public puzzles;

    constructor() public {
        escrowFactory = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == escrowFactory, "Can only be called by escrow factory");
        _;
    }

     
    function newEscrow(
        address escrowAddress,
        uint escrowAmount,
        uint timelock,
        address payable escrowerReserve,
        address escrowerTrade,
        address escrowerRefund,
        address payable payeeReserve,
        address payeeTrade
    )
        public
        onlyFactory
    {
        require(escrows[escrowAddress].escrowState == EscrowState.None, "Escrow already exists");
        require(escrowAmount > 0, "Escrow amount too low");

        uint escrowerStartingBalance = 0;
        uint payeeStartingBalance = 0;

        escrows[escrowAddress] = EscrowParams(
            escrowAmount,
            timelock,
            escrowerReserve,
            escrowerTrade,
            escrowerRefund,
            payeeReserve,
            payeeTrade,
            EscrowState.Unfunded,
            escrowerStartingBalance,
            payeeStartingBalance
        );

        EscrowParams storage escrowParams = escrows[escrowAddress];

        IEscrow escrow = IEscrow(escrowAddress);
        uint escrowBalance = escrow.balance();

         
        require(escrowBalance >= escrowAmount, "Escrow not funded");

        escrowParams.escrowState = EscrowState.Open;

         
        if(escrowBalance > escrowAmount) {
           escrow.send(escrowParams.escrowerReserve, escrowBalance.sub(escrowAmount));
        }
    }

     
    function cashout(
        address escrowAddress,
        uint amountTraded,
        bytes memory eSig,
        bytes memory pSig
    )
        public
    {
        EscrowParams storage escrowParams = escrows[escrowAddress];
        require(escrowParams.escrowState == EscrowState.Open, "Escrow must be in state Open");

         
        string memory messageLength = '53';
        bytes32 sighash = keccak256(abi.encodePacked(
            SIGNATURE_PREFIX,
            messageLength,
            escrowAddress,
            uint8(MessageTypeId.Cashout),
            amountTraded
        ));

         
        require(verify(sighash, eSig) == escrowParams.escrowerTrade, "Invalid escrower cashout sig");
        require(verify(sighash, pSig) == escrowParams.payeeTrade, "Invalid payee cashout sig");

        escrowParams.payeeBalance = amountTraded;
        escrowParams.escrowerBalance = escrowParams.escrowAmount.sub(amountTraded);
        escrowParams.escrowState = EscrowState.Closed;

        if(escrowParams.escrowerBalance > 0) sendEscrower(escrowAddress, escrowParams);
        if(escrowParams.payeeBalance > 0) sendPayee(escrowAddress, escrowParams);

        emit EscrowClosed(escrowAddress, EscrowCloseReason.Cashout, sighash);
    }

     
    function refund(address escrowAddress, uint amountTraded, bytes memory eSig) public {
        EscrowParams storage escrowParams = escrows[escrowAddress];
        require(escrowParams.escrowState == EscrowState.Open, "Escrow must be in state Open");
        require(now >= escrowParams.escrowTimelock, "Escrow timelock not reached");
        
         
        string memory messageLength = '53';
        bytes32 sighash = keccak256(abi.encodePacked(
            SIGNATURE_PREFIX,
            messageLength,
            escrowAddress,
            uint8(MessageTypeId.Refund),
            amountTraded
        ));

         
        require(verify(sighash, eSig) == escrowParams.escrowerRefund, "Invalid escrower sig");

        escrowParams.payeeBalance = amountTraded;
        escrowParams.escrowerBalance = escrowParams.escrowAmount.sub(amountTraded);
        escrowParams.escrowState = EscrowState.Closed;

        if(escrowParams.escrowerBalance > 0) sendEscrower(escrowAddress, escrowParams);
        if(escrowParams.payeeBalance > 0) sendPayee(escrowAddress, escrowParams);

        emit EscrowClosed(escrowAddress, EscrowCloseReason.Refund, sighash);
    }

     
    function forceRefund(address escrowAddress) public {
        EscrowParams storage escrowParams = escrows[escrowAddress];
        require(escrowParams.escrowState == EscrowState.Open, "Escrow must be in state Open");
        require(now >= escrowParams.escrowTimelock + FORCE_REFUND_TIME, "Escrow force refund timelock not reached");

        escrowParams.escrowerBalance = IEscrow(escrowAddress).balance();
        escrowParams.escrowState = EscrowState.Closed;

        if(escrowParams.escrowerBalance > 0) sendEscrower(escrowAddress, escrowParams);

         
        emit EscrowClosed(escrowAddress, EscrowCloseReason.ForceRefund, 0x0);
    }

     
    function postPuzzle(
        address escrowAddress,
        uint prevAmountTraded,
        uint tradeAmount,
        bytes32 puzzle,
        uint puzzleTimelock,
        bytes memory eSig,
        bytes memory pSig
    )
        public
    {
        EscrowParams storage escrowParams = escrows[escrowAddress];
        require(escrowParams.escrowState == EscrowState.Open, "Escrow must be in state Open");

         
        string memory messageLength = '149';
        bytes32 sighash = keccak256(abi.encodePacked(
            SIGNATURE_PREFIX,
            messageLength,
            escrowAddress,
            uint8(MessageTypeId.Puzzle),
            prevAmountTraded,
            tradeAmount,
            puzzle,
            puzzleTimelock
        ));

        require(verify(sighash, eSig) == escrowParams.escrowerTrade, "Invalid escrower sig");
        require(verify(sighash, pSig) == escrowParams.payeeTrade, "Invalid payee sig");

        puzzles[escrowAddress] = PuzzleParams(
            tradeAmount,
            puzzle,
            puzzleTimelock,
            sighash
        );

        escrowParams.escrowState = EscrowState.PuzzlePosted;
        escrowParams.payeeBalance = prevAmountTraded;
        escrowParams.escrowerBalance = escrowParams.escrowAmount.sub(prevAmountTraded).sub(tradeAmount);

        emit PuzzlePosted(escrowAddress, sighash);
    }

     
    function solvePuzzle(address escrowAddress, bytes32 preimage) public {
        EscrowParams storage escrowParams = escrows[escrowAddress];
        require(escrowParams.escrowState == EscrowState.PuzzlePosted, "Escrow must be in state PuzzlePosted");

        PuzzleParams memory puzzleParams = puzzles[escrowAddress];
        bytes32 h = sha256(abi.encodePacked(preimage));
        require(h == puzzleParams.puzzle, "Invalid preimage");
        emit Preimage(escrowAddress, preimage, puzzleParams.puzzleSighash);

        escrowParams.payeeBalance = escrowParams.payeeBalance.add(puzzleParams.tradeAmount);
        escrowParams.escrowState = EscrowState.Closed;

        emit EscrowClosed(escrowAddress, EscrowCloseReason.PuzzleSolve, puzzleParams.puzzleSighash);
    }

     
    function refundPuzzle(address escrowAddress) public {
        EscrowParams storage escrowParams = escrows[escrowAddress];
        require(escrowParams.escrowState == EscrowState.PuzzlePosted, "Escrow must be in state PuzzlePosted");

        PuzzleParams memory puzzleParams = puzzles[escrowAddress];
        require(now >= puzzleParams.puzzleTimelock, "Puzzle timelock not reached");
        
        escrowParams.escrowerBalance = escrowParams.escrowerBalance.add(puzzleParams.tradeAmount);
        escrowParams.escrowState = EscrowState.Closed;

        emit EscrowClosed(escrowAddress, EscrowCloseReason.PuzzleRefund, puzzleParams.puzzleSighash);
    }

    function withdraw(address escrowAddress, bool escrower) public {
        EscrowParams storage escrowParams = escrows[escrowAddress];

        require(escrowParams.escrowState == EscrowState.Closed, "Withdraw attempted before escrow is closed");

        if(escrower) {
            require(escrowParams.escrowerBalance > 0, "escrower balance is 0");
            sendEscrower(escrowAddress, escrowParams);
        } else {
            require(escrowParams.payeeBalance > 0, "payee balance is 0");
            sendPayee(escrowAddress, escrowParams);
        }
    }

    function sendEscrower(address escrowAddress, EscrowParams storage escrowParams) internal {
        IEscrow escrow = IEscrow(escrowAddress);

        uint amountToSend = escrowParams.escrowerBalance;
        escrowParams.escrowerBalance = 0;
        require(escrow.send(escrowParams.escrowerReserve, amountToSend), "escrower send failure");

        emit FundsTransferred(escrowAddress, escrowParams.escrowerReserve);
    }

    function sendPayee(address escrowAddress, EscrowParams storage escrowParams) internal {
        IEscrow escrow = IEscrow(escrowAddress);

        uint amountToSend = escrowParams.payeeBalance;
        escrowParams.payeeBalance = 0;
        require(escrow.send(escrowParams.payeeReserve, amountToSend), "payee send failure");

        emit FundsTransferred(escrowAddress, escrowParams.payeeReserve);
    }

     
    function verify(bytes32 sighash, bytes memory sig) internal pure returns(address retAddr) {
        retAddr = ECDSA.recover(sighash, sig);
    }
}

 

pragma solidity ^0.5.0;

 
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;





 
contract EscrowFactory is Ownable {

    EscrowLibrary public escrowLibrary;

    constructor () public {
        escrowLibrary = new EscrowLibrary();
    }

    event EscrowCreated(
        bytes32 indexed escrowParams,
        address escrowAddress
    );

    function createEthEscrow(
        uint escrowAmount,
        uint timelock,
        address payable escrowerReserve,
        address escrowerTrade,
        address escrowerRefund,
        address payable payeeReserve,
        address payeeTrade
    )
    public
    {
        bytes32 escrowParamsHash = keccak256(abi.encodePacked(
            address(this),
            escrowAmount,
            timelock,
            escrowerReserve,
            escrowerTrade,
            escrowerRefund,
            payeeReserve,
            payeeTrade
        ));

        bytes memory constructorArgs = abi.encode(address(escrowLibrary));
        bytes memory bytecode = abi.encodePacked(type(EthEscrow).creationCode, constructorArgs);
        address escrowAddress = createEscrow(bytecode, escrowParamsHash);

        escrowLibrary.newEscrow(
            escrowAddress,
            escrowAmount,
            timelock,
            escrowerReserve,
            escrowerTrade,
            escrowerRefund,
            payeeReserve,
            payeeTrade
        );

        emit EscrowCreated(escrowParamsHash, escrowAddress);
    }

    function createEscrow(bytes memory code, bytes32 salt) internal returns (address) {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        return addr;
    }
}
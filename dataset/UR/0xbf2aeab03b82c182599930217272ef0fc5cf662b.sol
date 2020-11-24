 

pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;
 
 
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library ECTools {

     
     
    function recoverSigner(bytes32 _hashedMsg, string _sig) public pure returns (address) {
        require(_hashedMsg != 0x00);

         
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, _hashedMsg));

        if (bytes(_sig).length != 132) {
            return 0x0;
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes memory sig = hexstrToBytes(substring(_sig, 2, 132));
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v < 27 || v > 28) {
            return 0x0;
        }
        return ecrecover(prefixedHash, v, r, s);
    }

     
    function isSignedBy(bytes32 _hashedMsg, string _sig, address _addr) public pure returns (bool) {
        require(_addr != 0x0);

        return _addr == recoverSigner(_hashedMsg, _sig);
    }

     
    function hexstrToBytes(string _hexstr) public pure returns (bytes) {
        uint len = bytes(_hexstr).length;
        require(len % 2 == 0);

        bytes memory bstr = bytes(new string(len / 2));
        uint k = 0;
        string memory s;
        string memory r;
        for (uint i = 0; i < len; i += 2) {
            s = substring(_hexstr, i, i + 1);
            r = substring(_hexstr, i + 1, i + 2);
            uint p = parseInt16Char(s) * 16 + parseInt16Char(r);
            bstr[k++] = uintToBytes32(p)[31];
        }
        return bstr;
    }

     
    function parseInt16Char(string _char) public pure returns (uint) {
        bytes memory bresult = bytes(_char);
         
        if ((bresult[0] >= 48) && (bresult[0] <= 57)) {
            return uint(bresult[0]) - 48;
        } else if ((bresult[0] >= 65) && (bresult[0] <= 70)) {
            return uint(bresult[0]) - 55;
        } else if ((bresult[0] >= 97) && (bresult[0] <= 102)) {
            return uint(bresult[0]) - 87;
        } else {
            revert();
        }
    }

     
     
    function uintToBytes32(uint _uint) public pure returns (bytes b) {
        b = new bytes(32);
        assembly {mstore(add(b, 32), _uint)}
    }

     
     
    function toEthereumSignedMessage(string _msg) public pure returns (bytes32) {
        uint len = bytes(_msg).length;
        require(len > 0);
        bytes memory prefix = "\x19Ethereum Signed Message:\n";
        return keccak256(abi.encodePacked(prefix, uintToString(len), _msg));
    }

     
    function uintToString(uint _uint) public pure returns (string str) {
        uint len = 0;
        uint m = _uint + 0;
        while (m != 0) {
            len++;
            m /= 10;
        }
        bytes memory b = new bytes(len);
        uint i = len - 1;
        while (_uint != 0) {
            uint remainder = _uint % 10;
            _uint = _uint / 10;
            b[i--] = byte(48 + remainder);
        }
        str = string(b);
    }


     
     
    function substring(string _str, uint _startIndex, uint _endIndex) public pure returns (string) {
        bytes memory strBytes = bytes(_str);
        require(_startIndex <= _endIndex);
        require(_startIndex >= 0);
        require(_endIndex <= strBytes.length);

        bytes memory result = new bytes(_endIndex - _startIndex);
        for (uint i = _startIndex; i < _endIndex; i++) {
            result[i - _startIndex] = strBytes[i];
        }
        return string(result);
    }
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
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ChannelManager {
    using SafeMath for uint256;

    string public constant NAME = "Channel Manager";
    string public constant VERSION = "0.0.1";

    address public hub;
    uint256 public challengePeriod;
    ERC20 public approvedToken;

    uint256 public totalChannelWei;
    uint256 public totalChannelToken;

    event DidHubContractWithdraw (
        uint256 weiAmount,
        uint256 tokenAmount
    );

     
     
     
     
     
    event DidUpdateChannel (
        address indexed user,
        uint256 senderIdx,  
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256[4] pendingWeiUpdates,  
        uint256[4] pendingTokenUpdates,  
        uint256[2] txCount,  
        bytes32 threadRoot,
        uint256 threadCount
    );

     
     
     
    event DidStartExitChannel (
        address indexed user,
        uint256 senderIdx,  
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256[2] txCount,  
        bytes32 threadRoot,
        uint256 threadCount
    );

    event DidEmptyChannel (
        address indexed user,
        uint256 senderIdx,  
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256[2] txCount,  
        bytes32 threadRoot,
        uint256 threadCount
    );

    event DidStartExitThread (
        address user,
        address indexed sender,
        address indexed receiver,
        uint256 threadId,
        address senderAddress,  
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256 txCount
    );

    event DidChallengeThread (
        address indexed sender,
        address indexed receiver,
        uint256 threadId,
        address senderAddress,  
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256 txCount
    );

    event DidEmptyThread (
        address user,
        address indexed sender,
        address indexed receiver,
        uint256 threadId,
        address senderAddress,  
        uint256[2] channelWeiBalances,
        uint256[2] channelTokenBalances,
        uint256[2] channelTxCount,
        bytes32 channelThreadRoot,
        uint256 channelThreadCount
    );

    event DidNukeThreads(
        address indexed user,
        address senderAddress,  
        uint256 weiAmount,  
        uint256 tokenAmount,  
        uint256[2] channelWeiBalances,
        uint256[2] channelTokenBalances,
        uint256[2] channelTxCount,
        bytes32 channelThreadRoot,
        uint256 channelThreadCount
    );

    enum ChannelStatus {
       Open,
       ChannelDispute,
       ThreadDispute
    }

    struct Channel {
        uint256[3] weiBalances;  
        uint256[3] tokenBalances;  
        uint256[2] txCount;  
        bytes32 threadRoot;
        uint256 threadCount;
        address exitInitiator;
        uint256 channelClosingTime;
        ChannelStatus status;
    }

    struct Thread {
        uint256[2] weiBalances;  
        uint256[2] tokenBalances;  
        uint256 txCount;  
        uint256 threadClosingTime;
        bool[2] emptied;  
    }

    mapping(address => Channel) public channels;
    mapping(address => mapping(address => mapping(uint256 => Thread))) threads;  

    bool locked;

    modifier onlyHub() {
        require(msg.sender == hub);
        _;
    }

    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    constructor(address _hub, uint256 _challengePeriod, address _tokenAddress) public {
        hub = _hub;
        challengePeriod = _challengePeriod;
        approvedToken = ERC20(_tokenAddress);
    }

    function hubContractWithdraw(uint256 weiAmount, uint256 tokenAmount) public noReentrancy onlyHub {
        require(
            getHubReserveWei() >= weiAmount,
            "hubContractWithdraw: Contract wei funds not sufficient to withdraw"
        );
        require(
            getHubReserveTokens() >= tokenAmount,
            "hubContractWithdraw: Contract token funds not sufficient to withdraw"
        );

        hub.transfer(weiAmount);
        require(
            approvedToken.transfer(hub, tokenAmount),
            "hubContractWithdraw: Token transfer failure"
        );

        emit DidHubContractWithdraw(weiAmount, tokenAmount);
    }

    function getHubReserveWei() public view returns (uint256) {
        return address(this).balance.sub(totalChannelWei);
    }

    function getHubReserveTokens() public view returns (uint256) {
        return approvedToken.balanceOf(address(this)).sub(totalChannelToken);
    }

    function hubAuthorizedUpdate(
        address user,
        address recipient,
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256[4] pendingWeiUpdates,  
        uint256[4] pendingTokenUpdates,  
        uint256[2] txCount,  
        bytes32 threadRoot,
        uint256 threadCount,
        uint256 timeout,
        string sigUser
    ) public noReentrancy onlyHub {
        Channel storage channel = channels[user];

        _verifyAuthorizedUpdate(
            channel,
            txCount,
            weiBalances,
            tokenBalances,
            pendingWeiUpdates,
            pendingTokenUpdates,
            timeout,
            true
        );

        _verifySig(
            [user, recipient],
            weiBalances,
            tokenBalances,
            pendingWeiUpdates,  
            pendingTokenUpdates,  
            txCount,
            threadRoot,
            threadCount,
            timeout,
            "",  
            sigUser,
            [false, true]  
        );

        _updateChannelBalances(channel, weiBalances, tokenBalances, pendingWeiUpdates, pendingTokenUpdates);

         
        recipient.transfer(pendingWeiUpdates[3]);
        require(approvedToken.transfer(recipient, pendingTokenUpdates[3]), "user token withdrawal transfer failed");

         
        channel.txCount = txCount;
        channel.threadRoot = threadRoot;
        channel.threadCount = threadCount;

        emit DidUpdateChannel(
            user,
            0,  
            weiBalances,
            tokenBalances,
            pendingWeiUpdates,
            pendingTokenUpdates,
            txCount,
            threadRoot,
            threadCount
        );
    }

    function userAuthorizedUpdate(
        address recipient,
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256[4] pendingWeiUpdates,  
        uint256[4] pendingTokenUpdates,  
        uint256[2] txCount,  
        bytes32 threadRoot,
        uint256 threadCount,
        uint256 timeout,
        string sigHub
    ) public payable noReentrancy {
        require(msg.value == pendingWeiUpdates[2], "msg.value is not equal to pending user deposit");

        Channel storage channel = channels[msg.sender];

        _verifyAuthorizedUpdate(
            channel,
            txCount,
            weiBalances,
            tokenBalances,
            pendingWeiUpdates,
            pendingTokenUpdates,
            timeout,
            false
        );

        _verifySig(
            [msg.sender, recipient],
            weiBalances,
            tokenBalances,
            pendingWeiUpdates,  
            pendingTokenUpdates,  
            txCount,
            threadRoot,
            threadCount,
            timeout,
            sigHub,
            "",  
            [true, false]  
        );

         
        require(approvedToken.transferFrom(msg.sender, address(this), pendingTokenUpdates[2]), "user token deposit failed");

        _updateChannelBalances(channel, weiBalances, tokenBalances, pendingWeiUpdates, pendingTokenUpdates);

         
        recipient.transfer(pendingWeiUpdates[3]);
        require(approvedToken.transfer(recipient, pendingTokenUpdates[3]), "user token withdrawal transfer failed");

         
        channel.txCount = txCount;
        channel.threadRoot = threadRoot;
        channel.threadCount = threadCount;

        emit DidUpdateChannel(
            msg.sender,
            1,  
            weiBalances,
            tokenBalances,
            pendingWeiUpdates,
            pendingTokenUpdates,
            channel.txCount,
            channel.threadRoot,
            channel.threadCount
        );
    }

     

     
    function startExit(
        address user
    ) public noReentrancy {
        require(user != hub, "user can not be hub");
        require(user != address(this), "user can not be channel manager");

        Channel storage channel = channels[user];
        require(channel.status == ChannelStatus.Open, "channel must be open");

        require(msg.sender == hub || msg.sender == user, "exit initiator must be user or hub");

        channel.exitInitiator = msg.sender;
        channel.channelClosingTime = now.add(challengePeriod);
        channel.status = ChannelStatus.ChannelDispute;

        emit DidStartExitChannel(
            user,
            msg.sender == hub ? 0 : 1,
            [channel.weiBalances[0], channel.weiBalances[1]],
            [channel.tokenBalances[0], channel.tokenBalances[1]],
            channel.txCount,
            channel.threadRoot,
            channel.threadCount
        );
    }

     
    function startExitWithUpdate(
        address[2] user,  
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256[4] pendingWeiUpdates,  
        uint256[4] pendingTokenUpdates,  
        uint256[2] txCount,  
        bytes32 threadRoot,
        uint256 threadCount,
        uint256 timeout,
        string sigHub,
        string sigUser
    ) public noReentrancy {
        Channel storage channel = channels[user[0]];
        require(channel.status == ChannelStatus.Open, "channel must be open");

        require(msg.sender == hub || msg.sender == user[0], "exit initiator must be user or hub");

        require(timeout == 0, "can't start exit with time-sensitive states");

        _verifySig(
            user,
            weiBalances,
            tokenBalances,
            pendingWeiUpdates,  
            pendingTokenUpdates,  
            txCount,
            threadRoot,
            threadCount,
            timeout,
            sigHub,
            sigUser,
            [true, true]  
        );

        require(txCount[0] > channel.txCount[0], "global txCount must be higher than the current global txCount");
        require(txCount[1] >= channel.txCount[1], "onchain txCount must be higher or equal to the current onchain txCount");

         
        require(weiBalances[0].add(weiBalances[1]) <= channel.weiBalances[2], "wei must be conserved");
        require(tokenBalances[0].add(tokenBalances[1]) <= channel.tokenBalances[2], "tokens must be conserved");

         
        if (txCount[1] == channel.txCount[1]) {
            _applyPendingUpdates(channel.weiBalances, weiBalances, pendingWeiUpdates);
            _applyPendingUpdates(channel.tokenBalances, tokenBalances, pendingTokenUpdates);

         
        } else {  
            _revertPendingUpdates(channel.weiBalances, weiBalances, pendingWeiUpdates);
            _revertPendingUpdates(channel.tokenBalances, tokenBalances, pendingTokenUpdates);
        }

         
         
         
        channel.txCount[0] = txCount[0];
        channel.threadRoot = threadRoot;
        channel.threadCount = threadCount;

        channel.exitInitiator = msg.sender;
        channel.channelClosingTime = now.add(challengePeriod);
        channel.status = ChannelStatus.ChannelDispute;

        emit DidStartExitChannel(
            user[0],
            msg.sender == hub ? 0 : 1,
            [channel.weiBalances[0], channel.weiBalances[1]],
            [channel.tokenBalances[0], channel.tokenBalances[1]],
            channel.txCount,
            channel.threadRoot,
            channel.threadCount
        );
    }

     
    function emptyChannelWithChallenge(
        address[2] user,
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256[4] pendingWeiUpdates,  
        uint256[4] pendingTokenUpdates,  
        uint256[2] txCount,  
        bytes32 threadRoot,
        uint256 threadCount,
        uint256 timeout,
        string sigHub,
        string sigUser
    ) public noReentrancy {
        Channel storage channel = channels[user[0]];
        require(channel.status == ChannelStatus.ChannelDispute, "channel must be in dispute");
        require(now < channel.channelClosingTime, "channel closing time must not have passed");

        require(msg.sender != channel.exitInitiator, "challenger can not be exit initiator");
        require(msg.sender == hub || msg.sender == user[0], "challenger must be either user or hub");

        require(timeout == 0, "can't start exit with time-sensitive states");

        _verifySig(
            user,
            weiBalances,
            tokenBalances,
            pendingWeiUpdates,  
            pendingTokenUpdates,  
            txCount,
            threadRoot,
            threadCount,
            timeout,
            sigHub,
            sigUser,
            [true, true]  
        );

        require(txCount[0] > channel.txCount[0], "global txCount must be higher than the current global txCount");
        require(txCount[1] >= channel.txCount[1], "onchain txCount must be higher or equal to the current onchain txCount");

         
        require(weiBalances[0].add(weiBalances[1]) <= channel.weiBalances[2], "wei must be conserved");
        require(tokenBalances[0].add(tokenBalances[1]) <= channel.tokenBalances[2], "tokens must be conserved");

         
        if (txCount[1] == channel.txCount[1]) {
            _applyPendingUpdates(channel.weiBalances, weiBalances, pendingWeiUpdates);
            _applyPendingUpdates(channel.tokenBalances, tokenBalances, pendingTokenUpdates);

         
        } else {  
            _revertPendingUpdates(channel.weiBalances, weiBalances, pendingWeiUpdates);
            _revertPendingUpdates(channel.tokenBalances, tokenBalances, pendingTokenUpdates);
        }

         
        channel.weiBalances[2] = channel.weiBalances[2].sub(channel.weiBalances[0]).sub(channel.weiBalances[1]);
        channel.tokenBalances[2] = channel.tokenBalances[2].sub(channel.tokenBalances[0]).sub(channel.tokenBalances[1]);

         
        totalChannelWei = totalChannelWei.sub(channel.weiBalances[0]).sub(channel.weiBalances[1]);
         
        user[0].transfer(channel.weiBalances[1]);
        channel.weiBalances[0] = 0;
        channel.weiBalances[1] = 0;

         
        totalChannelToken = totalChannelToken.sub(channel.tokenBalances[0]).sub(channel.tokenBalances[1]);
         
        require(approvedToken.transfer(user[0], channel.tokenBalances[1]), "user token withdrawal transfer failed");
        channel.tokenBalances[0] = 0;
        channel.tokenBalances[1] = 0;

         
         
         
        channel.txCount[0] = txCount[0];
        channel.threadRoot = threadRoot;
        channel.threadCount = threadCount;

        if (channel.threadCount > 0) {
            channel.status = ChannelStatus.ThreadDispute;
        } else {
            channel.channelClosingTime = 0;
            channel.status = ChannelStatus.Open;
        }

        channel.exitInitiator = address(0x0);

        emit DidEmptyChannel(
            user[0],
            msg.sender == hub ? 0 : 1,
            [channel.weiBalances[0], channel.weiBalances[1]],
            [channel.tokenBalances[0], channel.tokenBalances[1]],
            channel.txCount,
            channel.threadRoot,
            channel.threadCount
        );
    }

     
    function emptyChannel(
        address user
    ) public noReentrancy {
        require(user != hub, "user can not be hub");
        require(user != address(this), "user can not be channel manager");

        Channel storage channel = channels[user];
        require(channel.status == ChannelStatus.ChannelDispute, "channel must be in dispute");

        require(
          channel.channelClosingTime < now ||
          msg.sender != channel.exitInitiator && (msg.sender == hub || msg.sender == user),
          "channel closing time must have passed or msg.sender must be non-exit-initiating party"
        );

         
        channel.weiBalances[2] = channel.weiBalances[2].sub(channel.weiBalances[0]).sub(channel.weiBalances[1]);
        channel.tokenBalances[2] = channel.tokenBalances[2].sub(channel.tokenBalances[0]).sub(channel.tokenBalances[1]);

         
        totalChannelWei = totalChannelWei.sub(channel.weiBalances[0]).sub(channel.weiBalances[1]);
         
        user.transfer(channel.weiBalances[1]);
        channel.weiBalances[0] = 0;
        channel.weiBalances[1] = 0;

         
        totalChannelToken = totalChannelToken.sub(channel.tokenBalances[0]).sub(channel.tokenBalances[1]);
         
        require(approvedToken.transfer(user, channel.tokenBalances[1]), "user token withdrawal transfer failed");
        channel.tokenBalances[0] = 0;
        channel.tokenBalances[1] = 0;

        if (channel.threadCount > 0) {
            channel.status = ChannelStatus.ThreadDispute;
        } else {
            channel.channelClosingTime = 0;
            channel.status = ChannelStatus.Open;
        }

        channel.exitInitiator = address(0x0);

        emit DidEmptyChannel(
            user,
            msg.sender == hub ? 0 : 1,
            [channel.weiBalances[0], channel.weiBalances[1]],
            [channel.tokenBalances[0], channel.tokenBalances[1]],
            channel.txCount,
            channel.threadRoot,
            channel.threadCount
        );
    }

     
     
     

     
    function startExitThread(
        address user,
        address sender,
        address receiver,
        uint256 threadId,
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        bytes proof,
        string sig
    ) public noReentrancy {
        Channel storage channel = channels[user];
        require(channel.status == ChannelStatus.ThreadDispute, "channel must be in thread dispute phase");
        require(msg.sender == hub || msg.sender == user, "thread exit initiator must be user or hub");
        require(user == sender || user == receiver, "user must be thread sender or receiver");

        require(weiBalances[1] == 0 && tokenBalances[1] == 0, "initial receiver balances must be zero");

        Thread storage thread = threads[sender][receiver][threadId];

        require(thread.threadClosingTime == 0, "thread closing time must be zero");

        _verifyThread(sender, receiver, threadId, weiBalances, tokenBalances, 0, proof, sig, channel.threadRoot);

        thread.weiBalances = weiBalances;
        thread.tokenBalances = tokenBalances;
        thread.threadClosingTime = now.add(challengePeriod);

        emit DidStartExitThread(
            user,
            sender,
            receiver,
            threadId,
            msg.sender,
            thread.weiBalances,
            thread.tokenBalances,
            thread.txCount
        );
    }

     
    function startExitThreadWithUpdate(
        address user,
        address[2] threadMembers,  
        uint256 threadId,
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        bytes proof,
        string sig,
        uint256[2] updatedWeiBalances,  
        uint256[2] updatedTokenBalances,  
        uint256 updatedTxCount,
        string updateSig
    ) public noReentrancy {
        Channel storage channel = channels[user];
        require(channel.status == ChannelStatus.ThreadDispute, "channel must be in thread dispute phase");
        require(msg.sender == hub || msg.sender == user, "thread exit initiator must be user or hub");
        require(user == threadMembers[0] || user == threadMembers[1], "user must be thread sender or receiver");

        require(weiBalances[1] == 0 && tokenBalances[1] == 0, "initial receiver balances must be zero");

        Thread storage thread = threads[threadMembers[0]][threadMembers[1]][threadId];
        require(thread.threadClosingTime == 0, "thread closing time must be zero");

        _verifyThread(threadMembers[0], threadMembers[1], threadId, weiBalances, tokenBalances, 0, proof, sig, channel.threadRoot);

         
         
         

        require(updatedTxCount > 0, "updated thread txCount must be higher than 0");
        require(updatedWeiBalances[0].add(updatedWeiBalances[1]) == weiBalances[0], "sum of updated wei balances must match sender's initial wei balance");
        require(updatedTokenBalances[0].add(updatedTokenBalances[1]) == tokenBalances[0], "sum of updated token balances must match sender's initial token balance");

         
        _verifyThread(threadMembers[0], threadMembers[1], threadId, updatedWeiBalances, updatedTokenBalances, updatedTxCount, "", updateSig, bytes32(0x0));

        thread.weiBalances = updatedWeiBalances;
        thread.tokenBalances = updatedTokenBalances;
        thread.txCount = updatedTxCount;
        thread.threadClosingTime = now.add(challengePeriod);

        emit DidStartExitThread(
            user,
            threadMembers[0],
            threadMembers[1],
            threadId,
            msg.sender == hub ? 0 : 1,
            thread.weiBalances,
            thread.tokenBalances,
            thread.txCount
        );
    }

     
    function challengeThread(
        address sender,
        address receiver,
        uint256 threadId,
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256 txCount,
        string sig
    ) public noReentrancy {
        require(msg.sender == hub || msg.sender == sender || msg.sender == receiver, "only hub, sender, or receiver can call this function");

        Thread storage thread = threads[sender][receiver][threadId];
         
        require(now < thread.threadClosingTime, "thread closing time must not have passed");

         
        require(txCount > thread.txCount, "thread txCount must be higher than the current thread txCount");
        require(weiBalances[0].add(weiBalances[1]) == thread.weiBalances[0].add(thread.weiBalances[1]), "updated wei balances must match sum of thread wei balances");
        require(tokenBalances[0].add(tokenBalances[1]) == thread.tokenBalances[0].add(thread.tokenBalances[1]), "updated token balances must match sum of thread token balances");

        require(weiBalances[1] >= thread.weiBalances[1] && tokenBalances[1] >= thread.tokenBalances[1], "receiver balances may never decrease");

         
        _verifyThread(sender, receiver, threadId, weiBalances, tokenBalances, txCount, "", sig, bytes32(0x0));

         
        thread.weiBalances = weiBalances;
        thread.tokenBalances = tokenBalances;
        thread.txCount = txCount;

        emit DidChallengeThread(
            sender,
            receiver,
            threadId,
            msg.sender,
            thread.weiBalances,
            thread.tokenBalances,
            thread.txCount
        );
    }

     
    function emptyThread(
        address user,
        address sender,
        address receiver,
        uint256 threadId,
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        bytes proof,
        string sig
    ) public noReentrancy {
        Channel storage channel = channels[user];
        require(channel.status == ChannelStatus.ThreadDispute, "channel must be in thread dispute");
        require(msg.sender == hub || msg.sender == user, "only hub or user can empty thread");
        require(user == sender || user == receiver, "user must be thread sender or receiver");

        require(weiBalances[1] == 0 && tokenBalances[1] == 0, "initial receiver balances must be zero");

        Thread storage thread = threads[sender][receiver][threadId];

         
        require(thread.threadClosingTime != 0 && thread.threadClosingTime < now, "Thread closing time must have passed");

         
        require(!thread.emptied[user == sender ? 0 : 1], "user cannot empty twice");

         
        _verifyThread(sender, receiver, threadId, weiBalances, tokenBalances, 0, proof, sig, channel.threadRoot);

        require(thread.weiBalances[0].add(thread.weiBalances[1]) == weiBalances[0], "sum of thread wei balances must match sender's initial wei balance");
        require(thread.tokenBalances[0].add(thread.tokenBalances[1]) == tokenBalances[0], "sum of thread token balances must match sender's initial token balance");

         
        channel.weiBalances[2] = channel.weiBalances[2].sub(thread.weiBalances[0]).sub(thread.weiBalances[1]);
        channel.tokenBalances[2] = channel.tokenBalances[2].sub(thread.tokenBalances[0]).sub(thread.tokenBalances[1]);

         
        totalChannelWei = totalChannelWei.sub(thread.weiBalances[0]).sub(thread.weiBalances[1]);

         
        if (user == receiver) {
            user.transfer(thread.weiBalances[1]);
         
        } else if (user == sender) {
            user.transfer(thread.weiBalances[0]);
        }

         
        totalChannelToken = totalChannelToken.sub(thread.tokenBalances[0]).sub(thread.tokenBalances[1]);

         
        if (user == receiver) {
            require(approvedToken.transfer(user, thread.tokenBalances[1]), "user [receiver] token withdrawal transfer failed");
         
        } else if (user == sender) {
            require(approvedToken.transfer(user, thread.tokenBalances[0]), "user [sender] token withdrawal transfer failed");
        }

         
        thread.emptied[user == sender ? 0 : 1] = true;

         
        channel.threadCount = channel.threadCount.sub(1);

         
        if (channel.threadCount == 0) {
            channel.threadRoot = bytes32(0x0);
            channel.channelClosingTime = 0;
            channel.status = ChannelStatus.Open;
        }

        emit DidEmptyThread(
            user,
            sender,
            receiver,
            threadId,
            msg.sender,
            [channel.weiBalances[0], channel.weiBalances[1]],
            [channel.tokenBalances[0], channel.tokenBalances[1]],
            channel.txCount,
            channel.threadRoot,
            channel.threadCount
        );
    }


     
    function nukeThreads(
        address user
    ) public noReentrancy {
        require(user != hub, "user can not be hub");
        require(user != address(this), "user can not be channel manager");

        Channel storage channel = channels[user];
        require(channel.status == ChannelStatus.ThreadDispute, "channel must be in thread dispute");
        require(channel.channelClosingTime.add(challengePeriod.mul(10)) < now, "channel closing time must have passed by 10 challenge periods");

         
        totalChannelWei = totalChannelWei.sub(channel.weiBalances[2]);
        user.transfer(channel.weiBalances[2]);
        uint256 weiAmount = channel.weiBalances[2];
        channel.weiBalances[2] = 0;

         
        totalChannelToken = totalChannelToken.sub(channel.tokenBalances[2]);
        require(approvedToken.transfer(user, channel.tokenBalances[2]), "user token withdrawal transfer failed");
        uint256 tokenAmount = channel.tokenBalances[2];
        channel.tokenBalances[2] = 0;

         
        channel.threadCount = 0;
        channel.threadRoot = bytes32(0x0);
        channel.channelClosingTime = 0;
        channel.status = ChannelStatus.Open;

        emit DidNukeThreads(
            user,
            msg.sender,
            weiAmount,
            tokenAmount,
            [channel.weiBalances[0], channel.weiBalances[1]],
            [channel.tokenBalances[0], channel.tokenBalances[1]],
            channel.txCount,
            channel.threadRoot,
            channel.threadCount
        );
    }

    function() external payable {}

     
     
     

    function _verifyAuthorizedUpdate(
        Channel storage channel,
        uint256[2] txCount,
        uint256[2] weiBalances,
        uint256[2] tokenBalances,  
        uint256[4] pendingWeiUpdates,  
        uint256[4] pendingTokenUpdates,  
        uint256 timeout,
        bool isHub
    ) internal view {
        require(channel.status == ChannelStatus.Open, "channel must be open");

         
         
         
        require(timeout == 0 || now < timeout, "the timeout must be zero or not have passed");

        require(txCount[0] > channel.txCount[0], "global txCount must be higher than the current global txCount");
        require(txCount[1] >= channel.txCount[1], "onchain txCount must be higher or equal to the current onchain txCount");

         
        require(weiBalances[0].add(weiBalances[1]) <= channel.weiBalances[2], "wei must be conserved");
        require(tokenBalances[0].add(tokenBalances[1]) <= channel.tokenBalances[2], "tokens must be conserved");

         
        if (isHub) {
            require(pendingWeiUpdates[0].add(pendingWeiUpdates[2]) <= getHubReserveWei(), "insufficient reserve wei for deposits");
            require(pendingTokenUpdates[0].add(pendingTokenUpdates[2]) <= getHubReserveTokens(), "insufficient reserve tokens for deposits");
         
        } else {
            require(pendingWeiUpdates[0] <= getHubReserveWei(), "insufficient reserve wei for deposits");
            require(pendingTokenUpdates[0] <= getHubReserveTokens(), "insufficient reserve tokens for deposits");
        }

         
        require(channel.weiBalances[2].add(pendingWeiUpdates[0]).add(pendingWeiUpdates[2]) >=
                weiBalances[0].add(weiBalances[1]).add(pendingWeiUpdates[1]).add(pendingWeiUpdates[3]), "insufficient wei");

         
        require(channel.tokenBalances[2].add(pendingTokenUpdates[0]).add(pendingTokenUpdates[2]) >=
                tokenBalances[0].add(tokenBalances[1]).add(pendingTokenUpdates[1]).add(pendingTokenUpdates[3]), "insufficient token");
    }

    function _applyPendingUpdates(
        uint256[3] storage channelBalances,
        uint256[2] balances,
        uint256[4] pendingUpdates
    ) internal {
         
         
         
        if (pendingUpdates[0] > pendingUpdates[1]) {
            channelBalances[0] = balances[0].add(pendingUpdates[0].sub(pendingUpdates[1]));
         
         
        } else {
            channelBalances[0] = balances[0];
        }

         
         
         
        if (pendingUpdates[2] > pendingUpdates[3]) {
            channelBalances[1] = balances[1].add(pendingUpdates[2].sub(pendingUpdates[3]));

         
         
        } else {
            channelBalances[1] = balances[1];
        }
    }

    function _revertPendingUpdates(
        uint256[3] storage channelBalances,
        uint256[2] balances,
        uint256[4] pendingUpdates
    ) internal {
         
        if (pendingUpdates[0] > pendingUpdates[1]) {
            channelBalances[0] = balances[0];

         
        } else {
            channelBalances[0] = balances[0].add(pendingUpdates[1].sub(pendingUpdates[0]));  
        }

         
        if (pendingUpdates[2] > pendingUpdates[3]) {
            channelBalances[1] = balances[1];

         
        } else {
            channelBalances[1] = balances[1].add(pendingUpdates[3].sub(pendingUpdates[2]));  
        }
    }

    function _updateChannelBalances(
        Channel storage channel,
        uint256[2] weiBalances,
        uint256[2] tokenBalances,
        uint256[4] pendingWeiUpdates,
        uint256[4] pendingTokenUpdates
    ) internal {
        _applyPendingUpdates(channel.weiBalances, weiBalances, pendingWeiUpdates);
        _applyPendingUpdates(channel.tokenBalances, tokenBalances, pendingTokenUpdates);

        totalChannelWei = totalChannelWei.add(pendingWeiUpdates[0]).add(pendingWeiUpdates[2]).sub(pendingWeiUpdates[1]).sub(pendingWeiUpdates[3]);
        totalChannelToken = totalChannelToken.add(pendingTokenUpdates[0]).add(pendingTokenUpdates[2]).sub(pendingTokenUpdates[1]).sub(pendingTokenUpdates[3]);

         
        channel.weiBalances[2] = channel.weiBalances[2].add(pendingWeiUpdates[0]).add(pendingWeiUpdates[2]).sub(pendingWeiUpdates[1]).sub(pendingWeiUpdates[3]);
        channel.tokenBalances[2] = channel.tokenBalances[2].add(pendingTokenUpdates[0]).add(pendingTokenUpdates[2]).sub(pendingTokenUpdates[1]).sub(pendingTokenUpdates[3]);
    }

    function _verifySig (
        address[2] user,  
        uint256[2] weiBalances,  
        uint256[2] tokenBalances,  
        uint256[4] pendingWeiUpdates,  
        uint256[4] pendingTokenUpdates,  
        uint256[2] txCount,  
        bytes32 threadRoot,
        uint256 threadCount,
        uint256 timeout,
        string sigHub,
        string sigUser,
        bool[2] checks  
    ) internal view {
        require(user[0] != hub, "user can not be hub");
        require(user[0] != address(this), "user can not be channel manager");

         
        bytes32 state = keccak256(
            abi.encodePacked(
                address(this),
                user,  
                weiBalances,  
                tokenBalances,  
                pendingWeiUpdates,  
                pendingTokenUpdates,  
                txCount,  
                threadRoot,
                threadCount,
                timeout
            )
        );

        if (checks[0]) {
            require(hub == ECTools.recoverSigner(state, sigHub), "hub signature invalid");
        }

        if (checks[1]) {
            require(user[0] == ECTools.recoverSigner(state, sigUser), "user signature invalid");
        }
    }

    function _verifyThread(
        address sender,
        address receiver,
        uint256 threadId,
        uint256[2] weiBalances,
        uint256[2] tokenBalances,
        uint256 txCount,
        bytes proof,
        string sig,
        bytes32 threadRoot
    ) internal view {
        require(sender != receiver, "sender can not be receiver");
        require(sender != hub && receiver != hub, "hub can not be sender or receiver");
        require(sender != address(this) && receiver != address(this), "channel manager can not be sender or receiver");

        bytes32 state = keccak256(
            abi.encodePacked(
                address(this),
                sender,
                receiver,
                threadId,
                weiBalances,  
                tokenBalances,  
                txCount  
            )
        );
        require(ECTools.isSignedBy(state, sig, sender), "signature invalid");

        if (threadRoot != bytes32(0x0)) {
            require(_isContained(state, proof, threadRoot), "initial thread state is not contained in threadRoot");
        }
    }

    function _isContained(bytes32 _hash, bytes _proof, bytes32 _root) internal pure returns (bool) {
        bytes32 cursor = _hash;
        bytes32 proofElem;

        for (uint256 i = 64; i <= _proof.length; i += 32) {
            assembly { proofElem := mload(add(_proof, i)) }

            if (cursor < proofElem) {
                cursor = keccak256(abi.encodePacked(cursor, proofElem));
            } else {
                cursor = keccak256(abi.encodePacked(proofElem, cursor));
            }
        }

        return cursor == _root;
    }

    function getChannelBalances(address user) constant public returns (
        uint256 weiHub,
        uint256 weiUser,
        uint256 weiTotal,
        uint256 tokenHub,
        uint256 tokenUser,
        uint256 tokenTotal
    ) {
        Channel memory channel = channels[user];
        return (
            channel.weiBalances[0],
            channel.weiBalances[1],
            channel.weiBalances[2],
            channel.tokenBalances[0],
            channel.tokenBalances[1],
            channel.tokenBalances[2]
        );
    }

    function getChannelDetails(address user) constant public returns (
        uint256 txCountGlobal,
        uint256 txCountChain,
        bytes32 threadRoot,
        uint256 threadCount,
        address exitInitiator,
        uint256 channelClosingTime,
        ChannelStatus status
    ) {
        Channel memory channel = channels[user];
        return (
            channel.txCount[0],
            channel.txCount[1],
            channel.threadRoot,
            channel.threadCount,
            channel.exitInitiator,
            channel.channelClosingTime,
            channel.status
        );
    }
}
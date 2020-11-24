 

pragma solidity ^0.5.0 <0.6.0;

contract EtherSwap {
    struct Swap {
        uint256 amount;

        address payable claimAddress;
        address payable refundAddress;

        uint256 timelock;

         
        bool pending;
    }

    mapping (bytes32 => Swap) private swaps;

    event Claim(bytes32 _preimageHash);
    event Creation(bytes32 _preimageHash);
    event Refund(bytes32 _preimageHash);

    modifier onlyPendingSwaps(bytes32 _preimageHash) {
        require(swaps[_preimageHash].pending == true, "there is no pending swap with this preimage hash");
        _;
    }

    function create(bytes32 _preimageHash, address payable _claimAddress, uint256 _timelock) external payable {
        require(msg.value > 0, "the amount must not be zero");
        require(swaps[_preimageHash].amount == 0, "a swap with this preimage hash exists already");

         
        swaps[_preimageHash] = Swap({
            amount: msg.value,
            claimAddress: _claimAddress,
            refundAddress: msg.sender,
            timelock: _timelock,
            pending: true
        });

         
        emit Creation(_preimageHash);
    }

    function claim(bytes32 _preimageHash, bytes calldata _preimage) external onlyPendingSwaps(_preimageHash) {
        require(_preimageHash == sha256(_preimage), "the preimage does not correspond the provided hash");

        swaps[_preimageHash].pending = false;
        Swap memory swap = swaps[_preimageHash];

         
        swap.claimAddress.transfer(swap.amount);

         
        emit Claim(_preimageHash);
    }

    function refund(bytes32 _preimageHash) external onlyPendingSwaps(_preimageHash) {
        require(swaps[_preimageHash].timelock <= block.timestamp, "swap has not timed out yet");

        swaps[_preimageHash].pending = false;
        Swap memory swap = swaps[_preimageHash];

         
        swap.refundAddress.transfer(swap.amount);

         
        emit Refund(_preimageHash);
    }

    function getSwapInfo(bytes32 _preimageHash) external view returns (
        uint256 amount,
        address claimAddress,
        address refundAddress,
        uint256 timelock,
        bool pending
    ) {
        Swap memory swap = swaps[_preimageHash];
        return (swap.amount, swap.claimAddress, swap.refundAddress, swap.timelock, swap.pending);
    }
}
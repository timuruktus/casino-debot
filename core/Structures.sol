
interface Transactable{
    function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;
}

contract Structures {
    
}
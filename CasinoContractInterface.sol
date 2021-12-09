pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

interface CasinoContractInterface{

    struct Session{
        uint id;
        address[] participants;
        mapping(address => string) nicknames;
        mapping(address => uint) bets;
        bool done;
    }

    struct SessionResult{
        uint id;
        address[] participants;
        uint[] bets;
        address winner;
        uint timestamp;
    }

    function getCurrentSession() external returns (Session);
}
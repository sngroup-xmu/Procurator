from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple

from lark import Tree


@dataclass(frozen=True)
class ImportDecl:
    alias: str
    path: str
    entries_path: Optional[str] = None


@dataclass(frozen=True)
class LinkDecl:
    src: str
    dst: str
    port: str  # "ALL" or decimal string


@dataclass
class NodeDecl:
    name: str
    # None means "not specified in DSL" (we keep this so backends can provide a compatibility default)
    external_input: Optional[bool] = None
    statements: List[Tree] = field(default_factory=list)
    env_statements: List[Tree] = field(default_factory=list)
    assume_exprs: List[Tree] = field(default_factory=list)
    assert_exprs: List[Tree] = field(default_factory=list)


@dataclass
class HostDecl:
    name: str
    connect_to: Optional[str] = None
    statements: List[Tree] = field(default_factory=list)
    env_statements: List[Tree] = field(default_factory=list)
    assume_exprs: List[Tree] = field(default_factory=list)
    assert_exprs: List[Tree] = field(default_factory=list)


@dataclass
class GlobalDecl:
    # None means "not specified in DSL" (backend may apply its own default)
    queue_capacity: Optional[int] = None
    # None means "not specified in DSL" (backend may apply its own default)
    env_thread: Optional[bool] = None
    # None means "not specified in DSL" (backend may apply its own default)
    host_eager: Optional[bool] = None
    statements: List[Tree] = field(default_factory=list)
    assume_exprs: List[Tree] = field(default_factory=list)
    assert_exprs: List[Tree] = field(default_factory=list)
    reachability: List[Tuple[str, str]] = field(default_factory=list)
    runtime_reachability: List[Tuple[str, str]] = field(default_factory=list)
    symmetry_groups: List[List[str]] = field(default_factory=list)


@dataclass
class SpecModel:
    imports: Dict[str, ImportDecl] = field(default_factory=dict)  # alias -> decl
    links: List[LinkDecl] = field(default_factory=list)
    nodes: Dict[str, NodeDecl] = field(default_factory=dict)  # name -> decl
    hosts: Dict[str, HostDecl] = field(default_factory=dict)  # name -> decl
    global_decl: GlobalDecl = field(default_factory=GlobalDecl)

    def ensure_node(self, name: str) -> NodeDecl:
        if name not in self.nodes:
            self.nodes[name] = NodeDecl(name=name)
        return self.nodes[name]

    def ensure_host(self, name: str) -> HostDecl:
        if name not in self.hosts:
            self.hosts[name] = HostDecl(name=name)
        return self.hosts[name]

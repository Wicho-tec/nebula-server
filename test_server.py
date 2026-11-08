import json
import asyncio
import server
import websockets

def test_snapshot_incluye_a_los_jugadores():
    server.estado.clear()
    server.estado["ana"] = {"id": "ana", "x": 1.0, "y": 2.0}
    assert json.loads(server.snapshot())["e"]["ana"]["x"] == 1.0

def test_partida_es_5_vs_5():
    assert server.MAX_JUGADORES == 10


def test_registro_limite_y_desconexion_de_jugadores():
    async def comprobar():
        server.estado.clear()
        server.conexiones.clear()
        server.partida["iniciada"] = False
        clientes = []
        async with websockets.serve(server.jugador, "127.0.0.1", 0) as servidor:
            puerto = servidor.sockets[0].getsockname()[1]
            try:
                for _ in range(10):
                    ws = await websockets.connect(f"ws://127.0.0.1:{puerto}")
                    clientes.append(ws)
                    await ws.send(json.dumps({"ping": 1}))
                    assert json.loads(await ws.recv()) == {"pong": 1}
                assert len(server.conexiones) == 10
                assert server.partida["iniciada"]
                async with websockets.connect(f"ws://127.0.0.1:{puerto}") as extra:
                    await extra.wait_closed()
                    assert extra.close_code == 4000
            finally:
                for ws in clientes:
                    await ws.close()
        assert not server.conexiones
        assert not server.estado

    asyncio.run(comprobar())
